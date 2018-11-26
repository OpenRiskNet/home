After a restart of the glusterfs nodes some glusterfs volumes end up not being started correctly. Unless all 3 bricks are acitve the volume 
becomes read-only.

To find this:

```
$ oc rsh glusterfs-storage-7vf8r
sh-4.2# gluster vol list
... volumes listed
sh-4.2# gluster volume status vol_d9fd3e06266e04715b5ec105b9028a78
Status of volume: vol_d9fd3e06266e04715b5ec105b9028a78
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick 10.0.0.8:/var/lib/heketi/mounts/vg_60
e58df20c2e820762622eeb8d05bd7d/brick_1a4a8e
9b6a1a7b40ecf6eedc6b19292a/brick            49183     0          Y       676  
Brick 10.0.0.24:/var/lib/heketi/mounts/vg_5
d7331eb5a88ff6406b712f64ec900d8/brick_ac3de
9ef26acfc928d0a6bb673ba0335/brick           N/A       N/A        N       N/A  
Brick 10.0.0.18:/var/lib/heketi/mounts/vg_1
f988af5e34d453a2020f50b06d09137/brick_7dd3e
5b0c3e8888d37bae65e518be423/brick           49187     0          Y       710  
Self-heal Daemon on localhost               N/A       N/A        Y       72604
Self-heal Daemon on 10.0.0.8                N/A       N/A        Y       81558
Self-heal Daemon on 10.0.0.18               N/A       N/A        Y       81634
 
Task Status of Volume vol_d9fd3e06266e04715b5ec105b9028a78
------------------------------------------------------------------------------
There are no active volume tasks
```

To restart:
```
sh-4.2# gluster volume start vol_d9fd3e06266e04715b5ec105b9028a78 force
volume start: vol_d9fd3e06266e04715b5ec105b9028a78: success
```

Note: someetimes not all 3 bricks start. Need to investigate why.
