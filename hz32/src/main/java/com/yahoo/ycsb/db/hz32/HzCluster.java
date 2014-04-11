package com.yahoo.ycsb.db.hz32;

import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Created by danny on 4/8/14.
 */
public class HzCluster {

    public static final int nodesPerJvm = 1;
    public static final List<HazelcastInstance> nodes = new ArrayList();

    public static void main(String args[]){

        for(int i=0; i<nodesPerJvm; i++){
            nodes.add(Hazelcast.newHazelcastInstance());
        }

        final Random random = new Random();

        while(true){
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            IMap map = nodes.get(random.nextInt(nodesPerJvm)).getMap("usertable");

            System.out.println(map.getName()+" size = "+map.size());
        }
    }

}