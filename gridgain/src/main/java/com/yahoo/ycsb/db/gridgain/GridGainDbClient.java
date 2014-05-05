package com.yahoo.ycsb.db.gridgain;

import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.StringByteIterator;
import org.gridgain.client.*;

import java.util.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * A database interface layer for GridGain clients.
 */
public class GridGainDbClient extends DB {

    public Random random = new Random();

	public static final int OK = 0;
	public static final int ERROR = -1;

    public static final CountDownLatch initFinished = new CountDownLatch(1);
    public static  int nodesPerJVM;
    public static  boolean clientNodes;

    public static final AtomicBoolean doInit = new AtomicBoolean(true);
    public static final List<GridClient> nodez = new ArrayList();

	@Override
	public void init() throws DBException {
        System.err.println("==>> " + getClass().getName());

        GridClientDataConfiguration cacheConfig = new GridClientDataConfiguration();
        cacheConfig.setName("usertable");

        List<GridClientDataConfiguration> dataers = new ArrayList();
        dataers.add(cacheConfig);

        GridClientConfiguration configuration = new GridClientConfiguration();
        configuration.setDataConfigurations(dataers);

        if(doInit.compareAndSet(true, false)){

            Properties prop = getProperties();

            String nodesPerJVM_str = prop.getProperty("hazelcastDBClient.nodesPerJVM", "1");
            String clientNodes_str = prop.getProperty("hazelcastDbClient.clientNodes", "true");
            String clusterIps = prop.getProperty("hazelcastDbClient.clusterIPList", "");

            nodesPerJVM = Integer.parseInt(nodesPerJVM_str);
            clientNodes = Boolean.parseBoolean(clientNodes_str);

            List servers = new ArrayList();

            StringTokenizer st = new StringTokenizer(clusterIps, " ", false);
            while(st.hasMoreTokens()){
                String ip = st.nextToken();
                servers.add(ip+":"+11211);
            }
            configuration.setServers(servers);

            for(int i=0; i<nodesPerJVM; i++){
                if(clientNodes){
                    try {
                        GridClient client = GridClientFactory.start(configuration);
                        nodez.add(client);
                    } catch (GridClientException e) {
                        e.printStackTrace();
                    }
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
    }

	@Override
	public void cleanup() throws DBException {}

	@Override
	public int read(String table, String key, Set<String> fields, HashMap<String, ByteIterator> result) {

        GridClientData map = null;
        try {
            map = nodez.get(random.nextInt(nodez.size())).data(table);
        } catch (GridClientException e) {
            e.printStackTrace();
        }

        HashMap<String, String> row = null;
        try {
            row = map.get(key);
        } catch (GridClientException e) {
            e.printStackTrace();
        }

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

        GridClientData map = null;
        try {
            map = nodez.get(random.nextInt(nodez.size())).data(table);
        } catch (GridClientException e) {
            e.printStackTrace();
            return ERROR;
        }

        HashMap<String, String> row = null;
        try {
            row = map.get(key);
        } catch (GridClientException e) {
            e.printStackTrace();
        }

        if(row==null){
            return ERROR;
        }
        StringByteIterator.putAllAsStrings(row, values);
        try {
            map.put(key, row);
        } catch (GridClientException e) {
            e.printStackTrace();
            return ERROR;
        }

        return OK;
	}

	@Override
	public int insert(String table, String key, HashMap<String, ByteIterator> values) {

        GridClientData map = null;
        try {
            map = nodez.get(random.nextInt(nodez.size())).data(table);
        } catch (GridClientException e) {
            e.printStackTrace();
        }

        HashMap<String, String> row = new HashMap();
        StringByteIterator.putAllAsStrings(row, values);

        try {
            map.put(key, row);
        } catch (GridClientException e) {
            e.printStackTrace();
        }
        return OK;
    }

	@Override
	public int delete(String table, String key) {

        GridClientData map = null;
        try {
            map = nodez.get(random.nextInt(nodez.size())).data(table);
        } catch (GridClientException e) {
            e.printStackTrace();
            return ERROR;
        }

        try {
            map.remove(key);
        } catch (GridClientException e) {
            e.printStackTrace();
            return ERROR;
        }

        return OK;
	}

}