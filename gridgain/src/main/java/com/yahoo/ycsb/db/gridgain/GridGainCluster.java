package com.yahoo.ycsb.db.gridgain;


import org.gridgain.grid.*;
import org.gridgain.grid.cache.GridCache;
import org.gridgain.grid.cache.GridCacheConfiguration;
import org.gridgain.grid.cache.GridCacheDistributionMode;
import org.gridgain.grid.spi.communication.tcp.GridTcpCommunicationSpi;

import java.util.ArrayList;
import java.util.List;

public class GridGainCluster {

    public static int nodesPerJvm = 1;
    public static final List<Grid> nodes = new ArrayList();

    public static void main(String args[]){

        if(args!=null && args.length > 0){
            System.err.println("nodesPerJvm="+args[0]);
            nodesPerJvm = Integer.parseInt(args[0]);
        }

        GridConfiguration config = new GridConfiguration();

        GridCacheConfiguration cacheConfig = new GridCacheConfiguration();
        cacheConfig.setName("usertable");
        cacheConfig.setDistributionMode(GridCacheDistributionMode.PARTITIONED_ONLY);
        cacheConfig.setBackups(1);
        cacheConfig.setQueryIndexEnabled(false);


        config.setCacheConfiguration(cacheConfig);

        for(int i=0; i<nodesPerJvm; i++){

            try {
                Grid g = GridGain.start(config);
                nodes.add(g);
            } catch (GridException e) {
                e.printStackTrace();
            }
        }

        int targetSZ=2;

        if(args.length==2){
            targetSZ = Integer.parseInt(args[1]);
            System.err.println("Target Cluster Size="+targetSZ);
        }

        boolean go=true;
        while(go){

            try {
                Thread.sleep(8000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            for(Grid i : nodes ){
                int clusterSZ = GridGain.grid().nodes().size();
                if(clusterSZ == targetSZ){
                    System.err.println("===>>CLUSTERED<<===");
                    go=false;
                    break;
                }
            }
        }

        while(true){
            try {
                Thread.sleep(8000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            GridCache map = GridGain.grid().cache("usertable");
            System.out.println(map.name()+" size = "+map.size());
        }
    }
}