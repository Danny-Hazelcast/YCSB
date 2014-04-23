import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ListMultimap;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.DirectoryFileFilter;
import org.apache.commons.io.filefilter.RegexFileFilter;

import java.io.*;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.StringTokenizer;


public class ResultCombine {

    public static ListMultimap<String, Double> data = ArrayListMultimap.create();

    public static void main(String args[]) throws IOException {

        String dir = args[0];
        String fileNames = args[1];


        Collection<File> files = getfileNames( dir, fileNames );

        for(File f : files){
            try {
                //System.out.println(f.getName());
                BufferedReader in = new BufferedReader(new FileReader(f));
                addDataFrom(in);

            } catch (FileNotFoundException e) {
                e.printStackTrace();
            }
        }

        processData();
        if(fileNames.equals("runResult")){
            printRun();
        }
        else{
            printLoad();
        }
    }

    public static Collection<File> getfileNames(String path, String names){
        File dir = new File(path);


        Collection files = FileUtils.listFiles(
                dir,
                new RegexFileFilter(".*"+names+"\\.txt"),
                DirectoryFileFilter.DIRECTORY
        );

        return files;
    }



    public static void addDataFrom(BufferedReader in) throws IOException {
        String line;
        while ( (line = in.readLine()) !=null ) {

            StringTokenizer st = new StringTokenizer(line, ",", false);

            if(st.countTokens()==1){
                continue;
            }

            String key1 = st.nextToken();

            if(key1.matches("\\[CLEANUP\\].*")){
                break;
            }

            String key2 = st.nextToken();

            double value = Double.parseDouble(st.nextToken());

            data.put(key1+key2, value);
        }
    }

    public static void printOverall(){

        String key = "[OVERALL] RunTime(ms)";
        System.out.println(key+", "+data.get(key).get(0));

        key = "[OVERALL] Throughput(ops/sec)";
        System.out.println(key+", "+data.get(key).get(0));
    }

    public static void printRun(){

        printOverall();

        printData("[UPDATE]");
        printData("[READ]");
    }

    public static void printLoad(){

        printOverall();

        printData("[INSERT]");
    }

    public static void printData(String type){

        String key = type+" Operations";
        System.out.println(key+", "+data.get(key).get(0).intValue());

        key = type+" AverageLatency(us)";
        System.out.println(key+", "+data.get(key).get(0));

        key = type+" MinLatency(us)";
        System.out.println(key+", "+data.get(key).get(0));

        key = type+" MaxLatency(us)";
        System.out.println(key+", "+data.get(key).get(0));

        key = type+" 95thPercentileLatency(ms)";
        System.out.println(key+", "+data.get(key).get(0));

        key = type+" 99thPercentileLatency(ms)";
        System.out.println(key+", "+data.get(key).get(0));


        System.out.println(type+" Histogram");

        System.out.println("complete in ms, count");
        for(int i=0; i<1000; i++){
           key = type+" "+i;
           System.out.println(i+", "+data.get(key).get(0));
        }

        key = type+" >1000";
        System.out.println(">1000, "+data.get(key).get(0));
    }


    public static void processData(){

        for(int i=0; i<1000; i++){
            addTotal("[UPDATE] "+i);
            addTotal("[READ] "+i);
            addTotal("[INSERT] "+i);
        }

        addTotal("[UPDATE] >1000");
        addTotal("[READ] >1000");
        addTotal("[INSERT] >1000");

        addTotal("[UPDATE] Return=0");
        addTotal("[READ] Return=0");
        addTotal("[INSERT] Return=0");

        addTotal("[UPDATE] Operations");
        addTotal("[READ] Operations");
        addTotal("[INSERT] Operations");

        minOf("[READ] MinLatency(us)");
        maxOf("[READ] MaxLatency(us)");

        minOf("[UPDATE] MinLatency(us)");
        maxOf("[UPDATE] MaxLatency(us)");

        minOf("[INSERT] MinLatency(us)");
        maxOf("[INSERT] MaxLatency(us)");

        averageof("[UPDATE] AverageLatency(us)");
        averageof("[READ] AverageLatency(us)");
        averageof("[INSERT] AverageLatency(us)");

        maxOf("[UPDATE] 95thPercentileLatency(ms)");
        maxOf("[READ] 95thPercentileLatency(ms)");
        maxOf("[INSERT] 95thPercentileLatency(ms)");

        maxOf("[UPDATE] 99thPercentileLatency(ms)");
        maxOf("[READ] 99thPercentileLatency(ms)");
        maxOf("[INSERT] 99thPercentileLatency(ms)");

        maxOf("[OVERALL] RunTime(ms)");
        averageof("[OVERALL] Throughput(ops/sec)");
    }

    public static void averageof(String key){
        int count = data.get(key).size();
        if(count==0){
            return;
        }
        addTotal(key);

        double avg = data.get(key).get(0) / count;

        data.removeAll(key);
        data.put(key, avg);
    }

    public static void minOf(String key){
        List<Double> line = data.get(key);
        if(line!=null && line.size()>0){
            double min = Collections.min(line);
            data.removeAll(key);
            data.put(key, min);
        }
    }

    public static void maxOf(String key){
        List<Double> line = data.get(key);
        if(line!=null && line.size()>0){
            double max = Collections.max(line);
            data.removeAll(key);
            data.put(key, max);
        }
    }

    public static void addTotal(String key){
        List<Double> line = data.get(key);

        double total=0.0;
        for(double res : line){
            total+=res;
        }

        data.removeAll(key);

        data.put(key, total);
    }
}
