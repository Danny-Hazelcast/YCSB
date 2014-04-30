package com.yahoo.ycsb.db.infini2;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;

public class SimpleInfinispanClient{

    public static String address = "127.0.0.1:11222";
    public static String cacheName = "usertable";
    public static RemoteCacheManager remoteCacheManager;

    public static void main(String[] args){

        remoteCacheManager = new RemoteCacheManager(address);

        RemoteCache cache = remoteCacheManager.getCache(cacheName);

        System.err.println("cache.getName() = "+cache.getName());
        System.err.println("cache.isEmpty() = "+ cache.isEmpty());
        System.err.println("cache.size() = "+cache.size());

        System.err.println(remoteCacheManager.getMarshaller());
        try {
            boolean res = remoteCacheManager.getMarshaller().isMarshallable("key"+1);
            System.err.println(res);


            System.out.println( remoteCacheManager.getMarshaller().objectToByteBuffer("key"+0) );
        } catch (Exception e) {
            e.printStackTrace();
        }

        for(int i=0; i<3; i++){

            Object val = cache.get(i);
            System.err.println(val);
            cache.put(i, i);
        }
    }
}
