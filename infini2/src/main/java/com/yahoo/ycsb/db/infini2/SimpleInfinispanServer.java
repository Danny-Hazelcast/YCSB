package com.yahoo.ycsb.db.infini2;

import org.infinispan.Cache;
import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;
import org.infinispan.client.hotrod.impl.protocol.HotRodConstants;
import org.infinispan.configuration.cache.CacheMode;
import org.infinispan.configuration.cache.Configuration;
import org.infinispan.configuration.cache.ConfigurationBuilder;
import org.infinispan.configuration.global.GlobalConfigurationBuilder;
import org.infinispan.manager.DefaultCacheManager;
import org.infinispan.server.core.configuration.ProtocolServerConfiguration;
import org.infinispan.server.core.configuration.ProtocolServerConfigurationBuilder;
import org.infinispan.server.hotrod.HotRodServer;
import org.infinispan.server.hotrod.configuration.HotRodServerConfigurationBuilder;

import java.io.IOException;
import java.util.Random;

public class SimpleInfinispanServer {

    public static String cacheName = "usertable";

    public static DefaultCacheManager manager;
    public static HotRodServer hot;
    public static Cache map;

    public static void main(String[] args){

        manager = new DefaultCacheManager(
                new GlobalConfigurationBuilder().clusteredDefault().transport().defaultTransport().build(),
                new ConfigurationBuilder().build()
        );

        //Configuration c = new ConfigurationBuilder().clustering().cacheMode(CacheMode.DIST_SYNC).hash().numOwners(1).build();

        Configuration c = new ConfigurationBuilder().clustering().cacheMode(CacheMode.DIST_SYNC).hash().numOwners(1).build();


        manager.defineConfiguration(cacheName, c);

        ProtocolServerConfiguration pp = new HotRodServerConfigurationBuilder().build();

        hot = new HotRodServer();
        hot.start(pp, manager);

        map = manager.getCache(cacheName);

        while(true){
            try {
                Thread.sleep(8000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.err.println(map.size());

            map.putForExternalRead("key1", "HIHHIHIHIHIHIHIHIHIHI");

            for(Object k : map.keySet()){
                System.err.print( k +"="+map.get(k) + ", ");
            }
            System.err.println();
        }

    }
}