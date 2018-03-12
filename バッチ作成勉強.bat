@ECHO OFF
REM +--------------------------------------------------------------------+
REM | DESCRIPTION: | 各ttlマクロを実行
REM +--------------+-----------------------------------------------------+
 
REM 変数設定
set HOGE=変数の値
 
REM このバッチが存在するフォルダに移動し、そこを基点にする
REM cd /d %~dp0
pushd %~dp0
cls

REM 処理の一時停止:画面に「"続行するには何かキーを押してください . . ."」と表示
REM PAUSE >nul
 
REM ここらへんに処理を書く

start .\0.satellite1_status.ttl
timeout 20

start .\1.satellite1_standby.ttl
timeout /T 60 /NOBREAK

start .\2.satellite2_status.ttl
timeout /T 10 /NOBREAK


exit
REM 処理結果を戻す場合は、「EXIT /b」に変更。


