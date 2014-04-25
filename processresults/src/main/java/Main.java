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


public class Main {

    public static void main(String args[]) throws IOException {

        String choice = args[0];

        if(choice.equals("combine")){
            new ResultCombine(args);
        }
        else{
            new ReportResults(args);
        }
    }
}
