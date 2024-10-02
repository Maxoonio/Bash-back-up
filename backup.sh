#!/bin/bash
if [ "$1" == "/?" ]
then
echo Для создания бекапа введите bash backup.sh и следуйте инструкциям
echo Введите путь к папке, бекап которой нужно сделать в формате /path/directory
echo Введите нужное расширение файлов в формате .extension
echo Если нужно сохранить все файлы, то на вопросе о расширении нажмите Enter
echo Введите путь, по которому бекап будет сохранен в папку backup "(При вводе /home/nick бекап будет сохранен в /home/nick/backup)"
echo Также в папке backup будет находиться текстовый файл с ошибками при создании бекапа
echo Укажите, сколько копий бекапа может одновреенно храниться в папке, самая старая папка будет удаляться и заменяться на новую с указанной вами периодичностью 
echo Введенное число будет означать интервал между обновлениями в минутах
echo Если вы не хотите обновлять файл, то просто нажмите Enter
echo Если вы хотите перестать обновлять файл бекапа, введите bash backup -clear
echo Для получения справки Введите bash baskup.sh /? 
exit
fi
if [ "$1" == "-clear" ]
then
$(crontab -r)
exit
fi
if [ ! "$1" = "-c" ]
then
echo Для получения справки Введите bash baskup.sh /? 
read -p 'Укажите сохраняемый путь: ' path
read -p 'Расширение: ' ext
read -p 'Сохранить архив в: ' save 
read -p 'Сколько копий сделать?: ' n
read -p 'Как часто обновлять архив?: ' t
if [ $t ]
then
(crontab -l 2>/dev/null; echo "*/$t * * * * bash backup.sh -c $path $ext $save $n") | crontab -
fi
fi
if [ "$1" == "-c" ]
then
path=$2
ext=$3
save=$4
n=$5
fi
if [ ! -d "$save/backup" ]
then
$(mkdir $save/backup)
$(touch $save/backup/errors.txt)
fi
$(mkdir $save/backup/check)
name=$(date +%Y-%m-%d-%H:%M:%S)
cd $path
  for a in $(find $path -type f -and -printf "%f\n" -name "*$ext" )
  do
    tmp="${a#*$path}"
    if [ "${a:${#a} - ${#ext}}" = "$ext" ]
    then
    $(tar -rf "$save/backup/save_$name.tar" $tmp)
      checksum1=($(sha256sum $a)) # assignment to array to echo only the first element (the sum)
			tar -xf $save/backup/save_$name.tar -C $save/backup/check # unarchivation
			checksum2=($(sha256sum $save/backup/check/$a)) # checksum of unarchived file (it's equal to checksum of archived file)
			echo ARCHIVED FILE $a - $checksum2
      if [ "$checksum1" = "$checksum2" ] # comparation
			then
				echo SUCCESS
				echo 
			else
				echo FAIL
				echo "$save/backup/backup/save_$name.tar is not good" >> $save/backup/errors.txt
			fi
      $(touch $save/backup/errors.txt)
      if [[ $(find $save/backup -name "*.tar"| wc -l)  > $n ]]
      then
      $(cd $save/backup && ls -1 -lt | awk ' /^-/ { print $9}' | tail -1 | xargs rm)
      fi
    fi
  done

    $(rm -r $save/backup/check)
exit


