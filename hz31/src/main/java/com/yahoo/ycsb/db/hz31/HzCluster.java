package com.yahoo.ycsb.db.hz31;


import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;

/**
 * Created by danny on 4/8/14.
 */
public class HzCluster {

    public static void main(String args[]){

        HazelcastInstance node1 = Hazelcast.newHazelcastInstance();
        HazelcastInstance node2 = Hazelcast.newHazelcastInstance();


        while(true){
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            IMap map = node1.getMap("usertable");

            System.out.println(map.getName()+" size = "+map.size());
        }
    }

}
