package com.yahoo.ycsb.db.infini2;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;

public class SimpleInfinispanClient{

    public static String address = "127.0.0.1:11222";
    public static String cacheName = "usertable";
    public static RemoteCacheManager remoteCacheManager;

    public static void main(String[] args){

        remoteCacheManager = new RemoteCacheManager(address);

        RemoteCache<String, String> cache = remoteCacheManager.getCache(cacheName);

        System.err.println("cache.getName() = "+cache.getName());
        System.err.println("cache.isEmpty() = "+ cache.isEmpty());
        System.err.println("cache.size() = "+cache.size());

        for(int i=0; i<3; i++){

            String val = cache.get("key"+i);
            System.err.println(val);


            cache.put("key" + i, "value" + i);
        }
    }
}
