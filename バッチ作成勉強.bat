@ECHO OFF
REM +--------------------------------------------------------------------+
REM | DESCRIPTION: | �ettl�}�N�������s
REM +--------------+-----------------------------------------------------+
 
REM �ϐ��ݒ�
set HOGE=�ϐ��̒l
 
REM ���̃o�b�`�����݂���t�H���_�Ɉړ����A��������_�ɂ���
REM cd /d %~dp0
pushd %~dp0
cls

REM �����̈ꎞ��~:��ʂɁu"���s����ɂ͉����L�[�������Ă������� . . ."�v�ƕ\��
REM PAUSE >nul
 
REM ������ւ�ɏ���������

start .\0.satellite1_status.ttl
timeout 20

start .\1.satellite1_standby.ttl
timeout /T 60 /NOBREAK

start .\2.satellite2_status.ttl
timeout /T 10 /NOBREAK


exit
REM �������ʂ�߂��ꍇ�́A�uEXIT /b�v�ɕύX�B


