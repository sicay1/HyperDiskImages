� COPYRIGHT IBM CORP 1993 LICENSED MATERIAL - PROGRAM PROPERTY OF IBM              Y                =u�.�c.�I.�K.�W�G�.�.c`� ��uE�t	�W�h�5�5�/�!�c�e�g�%�/�!�, �I�!�����B� 1�!� L�!a�L�!      .� ��.�( �          VP� c�!��X^�W�� � �u
�. s��_�?PQVW�r�6;� �Pu���u�_^YX�PQVW��s
�W���
�6�� � _^YX�`�6��R�!��"&�?�6��>���&�=�u�� ��H�����&:t� G&�= v��>������ �uz����� �um�����	 �u`����� �uS�>�&�E.�[H��&� �Ё� ��u@��.�]&� & t7&�   &�   �5�� ��1��>�&�=�E����� ���'� ����� ����� �a�V&�G< v<	t<.t<ar<zw, �F������ ^�QVW�t_^YQVW� �_^Y�PQW�&�<ar<zw, ���_YX�PQV���3ɰ A�v��/����t���^YX��OG&�=	t�&�= t�r����&�G�� v��/u����SR���u�ڀ?$tC��C�Ӵ	�!Z[�
�C���X�^���X�Ƃ��ēo�^����܂����B
$
Registered as instance.
$
�p�����[�^�[������������܂���
$
Invalid parameter.
$
RAMBOOST �͂��̃t�@�C���� UMB �������[�Ƀ��[�h���Ă��܂���B
$
RAMBOOST didn't load this file into UMB memory.
$
���̃t�@�C���́A�T�C�Y���傫�����ēo�^�ł��܂���B
$
This file is too large to be registered.
$
���̃t�@�C���́A���ɓo�^����Ă��܂��B
$
This file has been already registered.
$
���̃t�@�C���́A�f�o�C�X�E�h���C�o�[�E�`�F�[���ɂ���܂���B
$
This file can't be found in device driver chain.
$
�w�肵���f�o�C�X�E�h���C�o�[�� Windows �̃C���X�^���X�Ƃ��ēo�^���܂��B
���g�p�̃f�o�C�X�E�h���C�o�[�� RAMBOOST �ɂ���� UMB �������[�Ƀ��[�h����A
Windows �̃C���X�^���X�ɂ��邱�Ƃ��ł��Ȃ��ꍇ�ɂ��g�p���������B

INSTANCE �t�@�C���� 

  �t�@�C�����@Windows �̃C���X�^���X�ɂ������f�o�C�X�E�h���C�o�[
              �̃t�@�C���� 

  (��) INSTANCE ANSI.SYS   
$
Registers specified device driver as Windows' instance.
Use this command if a device driver can't be Windows' instance
because RAMBOOST loads the driver into UMB memory.            

INSTANCE FileName  

  FileName  The name of device driver to be registered as
            Windows' instance

  (Example) INSTANCE ANSI.SYS
$