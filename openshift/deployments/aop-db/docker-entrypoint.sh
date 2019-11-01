echo "+> Copying data to target volume..."
cp -r /data/* /aopdbdata
ls
ls

echo "+> Post exit pause (5min)..."
   sleep 300
echo "+> Done."
