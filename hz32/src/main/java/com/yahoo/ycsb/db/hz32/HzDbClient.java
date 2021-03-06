package com.yahoo.ycsb.db.hz32;

import com.hazelcast.client.HazelcastClient;
import com.hazelcast.client.config.ClientConfig;
import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;
import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.StringByteIterator;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A database interface layer for Hazelcast.
 */
public class HzDbClient extends DB {

    public Random random = new Random();

	public static final int OK = 0;
	public static final int ERROR = -1;

    public static final CountDownLatch initFinished = new CountDownLatch(1);
    public static  int nodesPerJVM;
    public static  boolean clientNodes;

    public static final AtomicBoolean doInit = new AtomicBoolean(true);
    public static final List<HazelcastInstance> nodez = new ArrayList();

	@Override
	public void init() throws DBException {

        System.err.println("==>> "+getClass().getName() );

        if(doInit.compareAndSet(true, false)){

            Properties prop = getProperties();
            String nodesPerJVM_str = prop.getProperty("hazelcastDBClient.nodesPerJVM", "1");
            String clientNodes_str = prop.getProperty("hazelcastDbClient.clientNodes", "true");
            String clusterIps = prop.getProperty("hazelcastDbClient.clusterIPList", "");

            nodesPerJVM = Integer.parseInt(nodesPerJVM_str);
            clientNodes = Boolean.parseBoolean(clientNodes_str);

            for(int i=0; i<nodesPerJVM; i++){
                if(clientNodes){

                    ClientConfig config = new ClientConfig();

                    StringTokenizer st = new StringTokenizer(clusterIps, " ", false);
                    while(st.hasMoreTokens()){
                        String ip = st.nextToken();

                        config.getNetworkConfig().addAddress(ip);
                    }

                    nodez.add(HazelcastClient.newHazelcastClient(config));
                }else{
                    nodez.add(Hazelcast.newHazelcastInstance());
                }
            }

            initFinished.countDown();
            return;
        }

        try {
            System.err.println("waiting for initFinished");
            initFinished.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        if(!clientNodes){
            try {
                Thread.sleep(1000 * 60);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

	@Override
	public void cleanup() throws DBException {
		//Hazelcast.shutdownAll();
        System.err.println("CLEANUP END" );

    }

	@Override
	public int read(String table, String key, Set<String> fields, HashMap<String, ByteIterator> result) {

        IMap<String, HashMap<String, String> > map = nodez.get(random.nextInt(nodez.size())).getMap(table);
        HashMap<String, String> row = map.get(key);

        if(row==null){
            return ERROR;
        }

        if (fields == null || fields.isEmpty()) {
            StringByteIterator.putAllAsByteIterators(result, row);

        } else {
            for (String field : fields)
                result.put(field, new StringByteIterator(row.get(field)));
        }

		return OK;
	}

	@Override
	public int scan(String table, String startkey, int recordcount, Set<String> fields, Vector<HashMap<String, ByteIterator>> result) {
		System.err.println("Scan not implemented now");
		return ERROR;
	}

	@Override
	public int update(String table, String key, HashMap<String, ByteIterator> values) {


        IMap<String, HashMap<String, String> > map = nodez.get(random.nextInt(nodez.size())).getMap(table);
        HashMap<String, String> row = map.get(key);

        if(row==null){
            return ERROR;
        }
        StringByteIterator.putAllAsStrings(row, values);
        map.put(key, row);

        return OK;
	}

	@Override
	public int insert(String table, String key, HashMap<String, ByteIterator> values) {

        IMap<String, HashMap<String, String> > map = nodez.get(random.nextInt(nodez.size())).getMap(table);

        HashMap<String, String> row = new HashMap();
        StringByteIterator.putAllAsStrings(row, values);

        map.put(key, row);
        return OK;
    }

	@Override
	public int delete(String table, String key) {
        IMap map = nodez.get(random.nextInt(nodez.size())).getMap(table);
        map.remove(key);

		return OK;
	}

}