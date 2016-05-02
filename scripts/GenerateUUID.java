/** 
GenerateUUID.java

Trivial Java class to generate Type 4 universally unique IDs (UUIDs).
These UUIDs can be used, for instance, as CollectionSpace IDs (CSIDs).

Compile with: javac GenerateUUID.java
(This will create a class file named GenerateUUID.class)

Run with: java GenerateUUID
*/
import java.util.UUID;
public class GenerateUUID {
  public static void main( String args[] ) {
    UUID id = UUID.randomUUID();
    System.out.println( id.toString() );
  }
}
