import java.io.*;


public class Main {

    public static void main(String args[]) throws IOException {

        String choice = args[0];

        if(choice.equals("merge")){
            new Merge(args);
        }
        else{
            new Combine(args);
        }
    }
}
