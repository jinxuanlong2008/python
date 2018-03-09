#!/bin/bash

#### load_mergeスクリプトの説明
# [概要]
#  本スクリプトはNSO上から全vCPEに対してload mergeを実施し、コンフィグ投入を行うスクリプトです。
#  
# [実施例]
#  ./load_merge.sh [BASE.aio]
#    ⇒[BASE.aio]のファイル内を確認し、文字列「DEVICE_NAME」の箇所を各vCPEの名前に変更したファイルを作成する。
#      その後、作成したファイルを用いてload mergeを実施する
#
# [確認方法]
#  出力の最後に、以下が出力されれば正常終了
#      [INFO] end script (device sum = 180)
#        ⇒「180」の部分は実施対象となったvCPEの数が出力されます。





## デバッグモードで実施する場合は以下の2行のコメントアウトを解除する
#set -x
#trap read debug



## 引数の処理
# ベースとなるAIOファイル名

if [ $# -ne 1 ]; then
    # 引数が設定されていない場合は異常終了させる
    "[ERROR] No argument (ex : ./load_merge.sh [BASE.aio])"
    exit 1
fi

# ベースとなるAIOファイル名
AIO_BASE_FILE=$1
if [ ! -f "${AIO_BASE_FILE}" ]; then
     # 存在しないファイルを設定された場合は異常終了させる
     echo "[ERROR] No such file or directory [${AIO_BASE_FILE}]"
     exit 1
fi



## 変数の定義
# vCPE名に変更する箇所の文字列
CHG_DEVICE_NAME="DEVICE_NAME"



## スクリプト処理開始
echo "[INFO] start script..."



######## 状態確認 ########

echo "[INFO] show ncs-state ha"
ncs_state=`echo "show ncs-state ha" | ncs_cli -C -u info`
echo "${ncs_state}"

if [ -z "`echo "${ncs_state}" | grep "ncs-state ha mode master"`" ]; then
    # 対象のNSOがMasterでない場合、エラー終了とする
    echo "[ERROR] nso is not master. please change ncs-state ha"
    exit 1
fi



######## vCPEのリストアップ ########

echo "[INFO] show list up virtualCpe"
vcpe_list=`echo "show aio pods" | ncs_cli -C -u info | grep "^  virtualCpe"  | awk '{print $2}' | sort`
echo "${vcpe_list}"
if [ -z "${vcpe_list}" ]; then
    # vCPEが一つも取得できなかった場合、警告を出力させたうえで異常終了させる。
    echo "[WARN] there is not virtualCpe."
    exit 1
fi
echo "[INFO] device num = `echo "${vcpe_list}" | wc -l`"


######## 以降の処理は各デバイスごとに実施する ########
for vcpe_name in ${vcpe_list}
do
    echo "[INFO] start set config (device = ${vcpe_name})"
    
    ######## vCPE毎に投入するためのaioファイルを作成 ########
    # echo "[INFO] start make aio_file (device = ${vcpe_name})"
    sed -e "s/${CHG_DEVICE_NAME}/${vcpe_name}/g" ${AIO_BASE_FILE} > "${AIO_BASE_FILE}_tmp"
    if [ $? -ne 0 ]; then
        # aioファイルの作成に失敗(sedコマンドの返り値が0以外)なら異常終了させる。
        echo "[ERROR] Failed make aio_file (device = ${vcpe_name})"
        exit 1
    fi
  
    
    ######## コンフィグ投入を実施 ########
    # echo "[INFO] start set config (device = ${vcpe_name})"
    res=`ncs_cli -C << EOF
    config
    load merge "${AIO_BASE_FILE}_tmp"
    commit dry-run outformat cli
    commit
EOF`

#    res=`ncs_cli -C << EOF
#    config
#    load merge "${AIO_BASE_FILE}_tmp"
#    commit dry-run outformat cli
#EOF`

    # 異常終了させる前に作成したaioファイルを削除する
    rm "${AIO_BASE_FILE}_tmp"
           
    echo ${res} | tail -n 1 | grep "No modifications to commit." > /dev/null
    if [ $? -eq 0 ];then
        # 実行結果を確認し、最終行に「変更箇所無し」と表示されたら警告文を出したうえで異常終了させる。
        echo "[WARN] finish adding ${vcpe_name} No modifications to commit."
        echo -e "detail: ${res}"
        exit 1
    fi
    
    echo ${res} | tail -n 1 | grep "Commit complete." > /dev/null
    if [ $? -ne 0 ];then
        echo "[ERROR] finish adding ${vcpe_name} information from aio service."
        echo -e "detail: ${res}"
        exit 1
    fi
    # echo "[INFO] finish adding ${device} information from aio service."

done

echo "[INFO] end script (device num = `echo "${vcpe_list}" | wc -l`)"

