@echo off
c:
cd "C:\program files\7-Zip"
SET appName=premios-fans
SET sourceDir=D:\Projetos.Firebase\premios-fans
SET HOUR=%time:~0,2%
SET dtStamp9=%date:~6,4%-%date:~3,2%-%date:~0,2%_0%time:~1,1%-%time:~3,2%-%time:~6,2%
SET dtStamp24=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
if "%HOUR:~0,1%" == " " (SET dtStamp=%dtStamp9%) else (SET dtStamp=%dtStamp24%)
@echo BackUp de %appName%
@echo Diretorio de origem............: %sourceDir%
@echo Diretorio de destino do BackUp.: D:\Projetos.Firebase\_BackUps\%appName%
@echo Arquivo de saida...............: Source-%appName%_%dtStamp%.7z

7z a "D:\Projetos.Firebase\_backups\%appName%\Source-%appName%_%dtStamp%.7z" "%sourceDir%\*" -r -xr!node_modules -xr!.git
pause