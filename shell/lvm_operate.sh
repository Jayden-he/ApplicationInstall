#!/bin/bash

# 该脚本只允许在新增的磁盘上使用
#operate=$1
#mount_dir=$2
disk_name=$(fdisk -l 2> /dev/null | egrep "^Disk /dev/[s,h]d[[:alpha:]]" | awk -F: '{print $1}' | awk '{print $2}' | tail -n1)

vg_name="VG01"
lv_name="lv_data"


create_part(){
  # 创建分区
  #  fdisk /dev/sdc
  fdisk $1
  if [ $? -ne 0 ]; then
      echo "创建分区失败"
      exit 1
  fi
}

create_pv(){
  # 创建物理卷
  #  pvcreate /dev/sdc1
  pvcreate $1
  if [ $? -ne 0 ]; then
      echo "创建物理卷失败"
      exit 2
  fi
  # 查看物理卷
  #  pvdisplay /dev/sdc1
}

create_vg(){
  # 创建卷组
  # vgcreate myvg /dev/sdc1
  vgcreate $1 $2
  if [ $? -ne 0 ]; then
    echo "创建卷组失败"
    exit 3
  fi
  # 查看卷组
  #vgs
  #vgdisplay myvg
}

create_lv(){
  # 创建逻辑卷
  #  lvcreate -L 3G -n textlv myvg # -L 指定逻辑卷大小 -n 指定逻辑卷名称
  #  lvcreate -l 100%VG -n lv_3 vg_1  # -l指定逻辑卷所有空间
  #  lvcreate -l 80%Free -n lv_4 vg_1 # Free 剩余空间的80%
  lvcreate -l 100%VG -n $1 $2
  if [ $? -ne 0 ]; then
    echo "创建逻辑卷失败"
    exit 4
  fi
  # 查看逻辑卷
  #  lvs
  #  lvdisplay
}

create_filesystem(){
  # 创建文件系统
  #  mkfs -t xfs /dev/myvg/textlv
  # 新创建的逻辑卷路径格式为/dev/卷组名称/逻辑卷名称
  mkfs -t xfs $1
  if [ $? -ne 0 ]; then
    echo "创建文件系统失败"
    exit 5
  fi
}

add_pv_to_vg(){
  # 将pv加入到卷组
  #  vgextend VG01 /dev/sdc1  # 将pv /dev/sdc1加入到VG01 卷组
  vgextend $1 $2
  if [ $? -ne 0 ]; then
    echo "加入卷组失败"
    exit 6
  fi
}

extend_lv(){
  # 扩展逻辑卷大小
  # 想要扩展逻辑卷, 需要先保证卷组有足够的空闲空间可用, 先扩展物理边界, 在扩张逻辑边界, 即先扩卷组, 在扩逻辑卷
  # lvextend -L 8G /dev/myvg/textlv
  # resize2fs /dec/myvg/textlv
  lvextend -l 100%Free $1
  if [ $? -ne 0 ]; then
    echo "扩展逻辑卷失败"
    exit 7
  fi
}

mount_to_dir(){
  # 挂载到/data
  #  mount /dev/myvg/textlv /data
  mkdir -p $2
  mount $1 $2
  if [ $? -ne 0 ]; then
    echo "挂载失败"
    exit 8
  fi
}

main(){
  if [[ $disk_name = "/dev/sda" ]]; then
    echo $disk_name
    echo "/dev/sda不允许操作"
    exit 1
  fi
  echo $operate
  if [[ $operate = "create" ]]; then
    df | grep "$mount_dir"
    if [ $? -eq 0 ]; then
        echo "此挂载点已挂载，请更换挂载点"
        exit 2
    fi
    if [ -L /dev/$vg_name/$lv_name ]; then
        echo "/dev/$vg_name/$lv_name 已经存在, 只能扩容"
        exit 9
    fi
    create_pv $disk_name
    create_vg $vg_name $disk_name
    create_lv $lv_name $vg_name
    create_filesystem /dev/$vg_name/$lv_name
    mount_to_dir /dev/$vg_name/$lv_name $mount_dir
    echo "/dev/$vg_name/$lv_name $mount_dir xfs defaults,noatime,nobarrier 0 0" >> /etc/fstab
  elif [[ $operate = "extend" ]]; then
    create_pv $disk_name
    add_pv_to_vg $vg_name $disk_name
    extend_lv /dev/$vg_name/$lv_name
  fi
}

main








