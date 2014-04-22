package com.yahoo.ycsb.db.hz26;

import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class HzCluster {

    public static int nodesPerJvm = 1;
    public static final List<HazelcastInstance> nodes = new ArrayList();

    public static void main(String args[]){

        if(args!=null && args.length > 0){
            System.err.println("nodesPerJvm ="+args[0]);
            nodesPerJvm = Integer.parseInt(args[0]);
        }

        for(int i=0; i<nodesPerJvm; i++){
            nodes.add(Hazelcast.newHazelcastInstance());
        }

        final Random random = new Random();

        while(true){
            try {
                Thread.sleep(8000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            IMap map = nodes.get(random.nextInt(nodesPerJvm)).getMap("usertable");

            System.out.println(map.getName()+" size = "+map.size());
        }
    }

}
