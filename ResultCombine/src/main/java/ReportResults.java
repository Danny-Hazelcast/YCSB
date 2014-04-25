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


public class ReportResults {

    public static ListMultimap<String, Double> data = ArrayListMultimap.create();

    public static String version;

    public ReportResults(String args[]) throws IOException {

        String dir = args[1];
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

        printdata();
    }

    public static Collection<File> getfileNames(String path, String names){
        File dir = new File(path);

        Collection files = FileUtils.listFiles(
                dir,
                new RegexFileFilter(".*"+names+"\\.csv"),
                DirectoryFileFilter.DIRECTORY
        );

        return files;
    }

    public static void addDataFrom(BufferedReader in) throws IOException {
        String line;
        while ( (line = in.readLine()) !=null ) {

            StringTokenizer st = new StringTokenizer(line, ",", false);

            if(st.countTokens()==1){
                System.out.println(line);
                continue;
            }

            String key1 = st.nextToken();

            double value = Double.parseDouble(st.nextToken());
            data.put(key1, value);
        }
    }

    public static void printdata(){
        printData("[INSERT]");
        printData("[UPDATE]");
        printData("[READ]");
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
}
