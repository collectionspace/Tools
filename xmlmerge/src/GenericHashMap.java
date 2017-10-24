package xmlMerge;

import java.io.*;
import java.util.*;


public class GenericHashMap {
	
	private HashMap <String,String> genericHash;
	private Map.Entry <String,String> onegeneric;

	public GenericHashMap() {
	genericHash = new HashMap <String, String>();
	}
	
	public void put(String key, String value) {
		genericHash.put(key, value);
	}
	
	public String getval_fromHash(String key) {
		return genericHash.get(key);
	}
	
	public void show() {
		Set <Map.Entry <String,String> > hm = genericHash.entrySet();
		Iterator <Map.Entry <String,String> > it = hm.iterator();
		while (it.hasNext()) {
			onegeneric = it.next();
			System.out.println("objectNum: " + onegeneric.getKey() + 
					"\t generic: " + onegeneric.getValue());			
		}
	}
	
	public void write(BufferedWriter bw) {
		Set <Map.Entry <String,String> > hm = genericHash.entrySet();
		Iterator <Map.Entry <String,String> > it = hm.iterator();
		while (it.hasNext()) {
			onegeneric = it.next();
			try {
				bw.write("objectNum: " + onegeneric.getKey() + 
					"\t generic: " + onegeneric.getValue());
				bw.newLine(); 
			}
			catch (IOException e) {
				System.out.println("Ouput IO Exception!   " +e);
			}
		}		
	}
}
