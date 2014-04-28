import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ListMultimap;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.DirectoryFileFilter;
import org.apache.commons.io.filefilter.RegexFileFilter;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.data.category.DefaultCategoryDataset;

import java.io.*;
import java.util.*;


public class Combine {

    public static ListMultimap<String, String> data = ArrayListMultimap.create();

    public static Map<String, Double> versionedData = new HashMap();
    public static List<String> versions = new ArrayList<String>();

    public static String[] oppType = {"[INSERT]", "[UPDATE]", "[READ]"};

    public static String version;
    public static String dir;

    public Combine(String args[]) throws IOException {

        dir = args[1];
        String fileNames = args[2];


        Collection<File> files = getfileNames( dir, fileNames );

        for(File f : files){
            try {
                BufferedReader in = new BufferedReader(new FileReader(f));
                addDataFrom(in);

            } catch (FileNotFoundException e) {
                e.printStackTrace();
            }
        }

        makeChart("[OVERALL] Throughput(ops/sec)", "Throughput", "(ops/sec)", "throughput");
        makeChart(" AverageLatency(us)", "Average Latency", "(us)", "averageLatency");

        makeChart(" MaxLatency(us)", " Max Latency (us)", "us", "maxLatency");
        makeChart(" MinLatency(us)", " Min Latency (us)", "us", "minLatency");

        makeChart(" 95thPercentileLatency(ms)", "95th Percentile Latency (ms)", "ms", "95thPercentileLatency");
        makeChart(" 99thPercentileLatency(ms)", "99th Percentile Latency (ms)", "ms", "99thPercentileLatency");


        printdata();
    }

    public static Collection<File> getfileNames(String path, String names){
        File dir = new File(path);

        Collection files = FileUtils.listFiles(
                dir,
                new RegexFileFilter(".*"+names+".*"),
                DirectoryFileFilter.DIRECTORY
        );

        return files;
    }

    public static void addDataFrom(BufferedReader in) throws IOException {
        String line;
        while ( (line = in.readLine()) !=null ) {

            StringTokenizer st = new StringTokenizer(line, ",", false);
            String key1 = st.nextToken();
            String value = st.nextToken();

            data.put(key1, value);
        }

        String versionKey = "[version]";
        String version = data.get(versionKey).get(data.get(versionKey).size()-1);
        versions.add(version);

        for(String k : data.keySet()){

            if(!k.equals(versionKey)){

                String value = data.get(k).get(data.get(k).size()-1);

                if(versionedData.containsKey(version+k)){
                    System.out.println("!!!!!   BROKENooooooooooo ==="+ version+k );
                    System.exit(1);
                }

                versionedData.put(version+k, Double.parseDouble(value));
            }
        }
    }

    public static void printdata(){

        String key = "[version]";
        System.out.println(key+", "+data.get(key));

        for(String type : oppType){
            printData(type);
        }
    }

    public static void printData(String type){


        String key = type+"[OVERALL] RunTime(ms)";
        System.out.println(key+", "+data.get(key));

        key = type+"[OVERALL] Throughput(ops/sec)";
        System.out.println(key+", "+data.get(key));


        key = type+" Operations";
        System.out.println(key+", "+data.get(key));

        key = type+" Return=0";
        System.out.println(key+", "+data.get(key));

        key = type+" AverageLatency(us)";
        System.out.println(key+", "+data.get(key));

        key = type+" MinLatency(us)";
        System.out.println(key+", "+data.get(key));

        key = type+" MaxLatency(us)";
        System.out.println(key+", "+data.get(key));

        key = type+" 95thPercentileLatency(ms)";
        System.out.println(key+", "+data.get(key));

        key = type+" 99thPercentileLatency(ms)";
        System.out.println(key+", "+data.get(key));


        for(int i=0; i<1000; i++){
            key = type+" "+i;
            System.out.println(key+", "+data.get(key));
        }

        key = type+" >1000";
        System.out.println(key+", "+data.get(key));
    }


    public static void makeChart(String dataKey, String title, String rangeAxis, String fileName){

        DefaultCategoryDataset dataSet = new DefaultCategoryDataset();

        for(String version : versions){
            for(String type : oppType){

                String key = version+type+dataKey;
                double val = versionedData.get(key);
                dataSet.setValue(val, type, version);
            }
        }

        JFreeChart objChart = ChartFactory.createBarChart(
                title,     //Chart title
                "Systems",     //Domain axis label
                rangeAxis,         //Range axis label
                dataSet,         //Chart Data
                PlotOrientation.VERTICAL, // orientation
                true,             // include legend?
                true,             // include tooltips?
                false             // include URLs?
        );

        try {
            ChartUtilities.saveChartAsPNG(new File(dir+"/"+fileName+".png"), objChart, 500, 400);
        } catch (IOException e) {}
    }

}
