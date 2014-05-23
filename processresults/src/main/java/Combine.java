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

    //public static ListMultimap<String, String> data = ArrayListMultimap.create();

    public static Map<String, Double> versionedData = new HashMap();
    public static List<String> versions = new ArrayList<String>();

    public static String[] oppTypes = {"[INSERT]", "[UPDATE]", "[READ]"};


    public static String[] oppIds = {"[OVERALL] RunTime(ms)",
                                     "[OVERALL] Throughput(ops/sec)",
                                     " Operations",
                                     " Return=0",
                                     " AverageLatency(us)",
                                     " MinLatency(us)",
                                     " MaxLatency(us)",
                                     " 95thPercentileLatency(ms)",
                                     " 99thPercentileLatency(ms)"};


    public static String dir;
    public static double targetInserts;
    public static double targetOpps;

    public Combine(String args[]) throws IOException {

        dir = args[1];
        String fileNames = args[2];

        targetInserts = Double.parseDouble( args[3] );
        targetOpps  = Double.parseDouble( args[4] );

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

        printPossibleErrors();
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
        String line = in.readLine();

        StringTokenizer st = new StringTokenizer(line, ",", false);
        String versionKey = st.nextToken();
        String version = st.nextToken();

        versions.add(version);

        while ( (line = in.readLine()) !=null ) {

            st = new StringTokenizer(line, ",", false);
            String key = st.nextToken();
            String value = st.nextToken();

            versionedData.put(version+key, Double.parseDouble(value));
        }
    }

    public static void printdata(){

        System.out.print("[version]");
        for(String version : versions){
            System.out.print(","+version);
        }
        System.out.println();


        for(String type : oppTypes){
            for(String id : oppIds){

                printDataLine(type, id);
            }

            for(int i=0; i<1000; i++){
                printDataLine(type, " "+i);
            }

            printDataLine(type, " >1000");
        }
    }


    public static void printDataLine(String type, String id){

        System.out.print(type+id);
        for(String version : versions){

            String key = version + type + id;

            System.out.print(", "+versionedData.get(key));
        }
        System.out.println();
    }


    public static void makeChart(String dataKey, String title, String rangeAxis, String fileName){

        DefaultCategoryDataset dataSet = new DefaultCategoryDataset();

        for(String version : versions){
            for(String type : oppTypes){

                String key = version+type+dataKey;
                Double val = versionedData.get(key);
                if(val!=null){
                    dataSet.setValue(val, type, version);
                }
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
            ChartUtilities.saveChartAsPNG(new File(dir+"/"+fileName+".png"), objChart, 1024, 800);
        } catch (IOException e) {}
    }


    public static void printPossibleErrors(){

        for(String version : versions){

            String insertOppskey = version+"[INSERT]"+" Operations";
            Double totalInserts = versionedData.get(insertOppskey);

            if(totalInserts==null ||totalInserts != targetInserts){
                System.err.println(version+" did "+totalInserts+" "+insertOppskey+" out of "+targetInserts);
            }

            String updateOppskey = version+"[UPDATE]"+" Operations";
            Double totalUpdate = versionedData.get(updateOppskey);

            String readOppskey = version+"[READ]"+" Operations";
            Double totalRead = versionedData.get(readOppskey);


            if(totalUpdate==null || totalRead==null || totalUpdate + totalRead != targetOpps){
                System.err.println(version+" did not meet target operations count of "+targetOpps+" ( [UPDATE]="+totalUpdate+" [READ]="+totalRead+" )" );
            }

        }

        for(String version : versions){
            for(String type : oppTypes){

                String InsertOppskey = version+type+" Operations";
                String InsertOppsOkkey = version+type+" Return=0";

                Double totalOpps = versionedData.get(InsertOppskey);
                Double checkedOpps = versionedData.get(InsertOppsOkkey);

                if(totalOpps==null || checkedOpps==null || Math.round(totalOpps) != Math.round(checkedOpps) ){
                    System.err.println(version+" did "+totalOpps+" "+InsertOppskey+" only "+checkedOpps+" passed");
                }
            }
        }
    }

}
