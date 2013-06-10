package xmlMerge;

import java.io.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * MergeGeneric (plus GenericHashMap class) creates an merged XML payload that can
 * be used for the CSpace "import" service.  The idea is to merge the repeating
 * group XML (delta) into a main source XML by specifying the match-tag (link 
 * between the two files) and the merge-tag (what target repeating group in the  
 * delta file should be pulled into the source file).  The source XML file should 
 * contain all elements needed in the final XML payload --- for the repeating 
 * group portions, it should have at least the root of the repeating element 
 * (such as "colors" for collection objects) or repeating group (such as 
 * "taxonTermGroupList" for taxonomy authority).
 * 
 * Note: Only ONE repeating group can be merged in in each run, so to merge multiple 
 *       repeating groups, just run the program multiple times with each input from
 *       previous output.  Setting up such runs in a shell script or batch file is
 *       more convenient than run it individually on command line or inside IDE.
 * 
 * MergeGeneric main program equires 7 input arguments:
 * @param idKey           the tag containing the unique identifier for each record
 * @param merging_string  the tag indicating the to-be-merged portion from the delta
 * @param inXML_src       the source XML file name (idkey_tag can be anywhere in the record)
 * @param inXML_delta     the delta XML file name (idkey_tag must be positioned before merge_tag)
 * @param outXML          the output XML file name
 * @param full_match      boolean to indicate if all records in source are expected in delta
 *                        (if full_match is not required, the source data are maintained)
 * @param repl_or_app     value 1=replace 2=append (when matched)
 */

public class MergeGeneric {

    GenericHashMap hash = new GenericHashMap();
    static int NARGS = 7;
    static int REPLACE = 1;
    static int APPEND = 2;
    
	// content of merge_tag & merge_endtag is set in main.
	static String merge_tag;
	static String merge_endtag;
	static String merge_tag_selfclose;
	static String idKey_tag = "<collectionobjects_common:idKey>";
	static String idKey_endtag = "</collectionobjects_common:idKey>";
	
	public static void main (String[] args) {
	
		MergeGeneric merge = new MergeGeneric();	// Create an instance so we can get at non-static method
		
		String idKey_str, merge_str;
		String infl_src, infl_delta, outfl;
		boolean fullMatch;
		int repl_or_app = 0;
		
		if (args.length != NARGS) {
			System.out.println("Error: program \"MergeGeneric\" requires " + NARGS + " command line arguments.");
			System.out.println("       but " + args.length + " are detected!");  
			for(int i=0; i<args.length; i++) {
				System.out.println("       >> " + args[i]);
			}
			System.out.println("Usage: MergeGeneric idKey_string merge_string inXML_src inXML_delta outXML fullMatch repl_or_app");
			System.out.println("where both the idKey_string and merging_string may contain the namespace portion");
			System.out.println("   'fullMatch' is binary 1=all records in source are expected in delta; 0=otherwise");
			System.out.println("   'repl_or_app' code 1=replace; 2=append");
			System.exit(1);
		}
		idKey_str = args[0];
		merge_str = args[1];
		infl_src = args[2];
		infl_delta = args[3];
		outfl =  args[4];
		fullMatch =  args[5].equals("1") ? true : false;
		repl_or_app = args[6].equals("1") ? REPLACE : (args[6].equals("2") ? APPEND : 0);
		if (repl_or_app == 0)
		{
			System.out.println("Error: the last arguement 'repl_or_app' for program \"MergeGeneric2\"");
			System.out.println("       has to be coded as 1 for replacement, or 2 for appending");
			System.exit(1);
		}
		
		BufferedReader br_delta, br_source;
		BufferedWriter bw;
		
		idKey_tag = "<" + idKey_str + ">";
		idKey_endtag = "</" + idKey_str + ">";
		merge_tag = "<" + merge_str + ">";
		merge_endtag = "</" + merge_str + ">";
		merge_tag_selfclose = "<" + merge_str + "/>";   // self-closing w/o content value
		
		try {
			
			br_delta = new BufferedReader(new InputStreamReader(
					// new FileInputStream(new File("C:/informatics/XmlMerge/XmlMerge/XmlMergeSample/src/main/resources/tmsobj00b_out_split_match.xml"))
					new FileInputStream(new File(infl_delta))
				)
			);
			br_source = new BufferedReader(new InputStreamReader(
					// new FileInputStream(new File("C:/PAHMA-talend/PAHMA_ETL/temp/object/obj_cspace1.8out2011-10-31_00b0.xml"))
					// new FileInputStream(new File("C:/informatics/XmlMerge/XmlMerge/XmlMergeSample/src/main/resources/objout_trim4xmlMerge_5rec.xml"))
					new FileInputStream(new File(infl_src))
				)
			);
			// 2nd arg to FileOutputStream set to "true" will append file 
			// instead of overwrite it.
			bw = new BufferedWriter(new OutputStreamWriter(
					// new FileOutputStream(new File("C:/informatics/XmlMerge/XmlMerge/XmlMergeSample/target/javamerged_obj00b0.xml"), false)
					// new FileOutputStream(new File("C:/informatics/XmlMerge/XmlMerge/XmlMergeSample/target/javamerged_5rec.xml"), false)
					new FileOutputStream(new File(outfl), false)
				)
			);
		
			
			// Debugging test -- write delta to the output file
			// merge.read_delta(br_delta, bw);
			merge.read_delta(br_delta);
			
			merge.proc_source(br_source, bw, fullMatch, repl_or_app);

			br_source.close();
			br_delta.close();
			bw.close();
		}
		catch (FileNotFoundException e_nofile) {
			System.out.println("FileNotFound Exception!   " +e_nofile);
		}	
		catch (IOException e) {
			System.out.println("IO Exception!   " +e);
		}
	}

	// Debugging test -- write delta to the output file
	// public void read_delta(BufferedReader br_delta, BufferedWriter bw) {	
	public void read_delta(BufferedReader br_delta) {
		
		int ncases=0; 
		String line;
		
		// First search pattern is the idKey (tag + val + end_tag all in one line)
		String s_idKey = idKey_tag + "(.*)" + idKey_endtag;
	    Pattern p_idKey = Pattern.compile(s_idKey);
	    String s_matchKey = merge_tag + "(.*)" + merge_endtag;
	    Pattern p_matchKey = Pattern.compile(s_matchKey);
	    Pattern p_match = Pattern.compile(merge_tag);
	    Pattern p_match_end = Pattern.compile(merge_endtag);
	    Matcher m_idKey, m_matchKey, m_match, m_match_end;
	    
	    String idKey="";
	    String match="";

	    boolean got_id = false;
	    boolean start_match = false;
	    boolean got_match = false;
	    boolean match_before_id = false;
	    
		try {
			while ((line = br_delta.readLine()) != null)  {
				if (!got_id) {			// not yet read to "idKey"		 
					m_idKey = p_idKey.matcher(line);
					if (m_idKey.find()) {	
						idKey = m_idKey.group(1);
						got_id = true;
						// NEW -- check if got merge_tag content already, put into hash if so
						if (got_match && match_before_id) {
							hash.put(idKey, match);	// save key/value pa
							ncases++;
							got_id = false;	// reset for next object
							start_match = false;
							got_match = false;
							idKey = "";
							match = "";	// assignment not necessary, just for clarity	
						}
						continue;
					}
					else { // line doesn't contain "idKey", but may have "merge tag" first
						
						if (start_match && !got_match) {	// separately store all lines inside source's "merge tag" block
							m_match_end = p_match_end.matcher(line);							
							if (m_match_end.find()) { // mark if find the end of "merge tag" block
								got_match = true;								
							}
							match = match + line + "\n";	// store all lines inside delta's "merge tag" block
							continue;
						}
						// 3/30/2012: check if merge is on a single line first
						m_matchKey = p_matchKey.matcher(line);
						if (m_matchKey.find()) {	
							match = line + "\n";        // merge tag & content all in the line
							got_match = true;
							if (ncases == 0 && !got_id) {  // First case, see match before idKey
								match_before_id = true;
							}
							continue;
						}
						else {  // merge tag & content not all in one line
						    m_match = p_match.matcher(line);
							if (m_match.find()) {	// separately store all lines between source's "merge" bgn/end tag	
								start_match = true;
								if (ncases == 0 && !got_id) {  // First case, see match before idKey
									match_before_id = true;
								}
								match = match + line + "\n";	// store all lines inside delta's "merge tag" block		
								continue;
							}
						}  // end checking if merge_tag & merge_endtag are on the same line
					}
					continue;
				}
				else {	// got "idKey", now search for "merge tag"
					if (!start_match  && !got_match) {
						// 5/27/2012: check if merge is on a single line first
						m_matchKey = p_matchKey.matcher(line);
						if (m_matchKey.find()) {	
							match = line + "\n";        // merge tag & content all in the line
							if (ncases == 0) {  // First case, see idkey before match/merge Key
								match_before_id = false;
							}
							hash.put(idKey, match);	// save key/value pa
							ncases++;
							got_id = false;	// reset for next object
							start_match = false;
							got_match = false;
							idKey = "";
							match = "";	// assignment not necessary, just for clarity
							continue;
						}
						else {  // merge tag & content not all in one line
							m_match = p_match.matcher(line);
							if (m_match.find()) {	
								match = line + "\n";
								if (ncases == 0)  // First case, see idkey before match/merge Key
									match_before_id = false;
								start_match = true;
								got_match = false;
								continue;
							}
						}
					}
					else if (start_match && !got_match){
						m_match_end = p_match_end.matcher(line);
						match = match + line + "\n";	// end w/ the tag line
						if (m_match_end.find()) { // terminate match concatenation							
							got_match = true;					     
							hash.put(idKey, match);	// save key/value pa
							ncases++;
							got_id = false;	// reset for next object
							start_match = false;
							got_match = false;
							idKey = "";
							match = "";	// assignment not necessary, just for clarity
						}
						continue;
					}
				}
			}
			if (ncases < 10) hash.show();
			// Debugging -- write to output file
			// hash.write(bw);
			System.out.println("Total " + ncases + " processed in the delta file.");
		}
		catch (EOFException e_eof) {
			System.out.println("EOF Exception!   " + e_eof);
		}
		catch (IOException e) {
			System.out.println("IO Exception!   " +e);
		}
	}

	public void write_merge_block(BufferedWriter bw, boolean fullMatch, String idKey, String copysrc, 
			                      int repl_or_app, boolean selfclose, boolean samelineData) 
	{
		
		String newline = "\n";
		// Since I put out "\n" when I collected the delta data, it's best to stick to searching "\n"
		// rather than use system's line.separator (Windows will use \r\n which makes searching "\n" OK anyway)
		//     String newline = System.getProperty("line.separator");
		//     System.out.println("line.separator in system = \"" + newline + "\"");
		String RgtAngle = ">", LftAngle = "<";
		
		try {
			if (hash.getval_fromHash(idKey) == null) {
				if (fullMatch) {
					System.out.println("ERROR: at least one of the \"idKey\" doesn't have a matching record in the delta file");
					System.out.println("       Please check that the command line argments are given correctly.");
					System.out.println("Usage: MergeGeneric2 idKey_string merge_string inXML_src inXML_delta outXML fullMatch");
					System.out.println("where both the idKey_string and merging_string may contain the namespace portion");
					System.out.println("and 'fullMatch' is binary 1=all records in source are expected in delta; 0=otherwise");
					System.exit(1);
				}
				else {
					bw.write(copysrc);
				}
			}
			else {
				System.out.println("Match delta idkey: " + idKey);	// DEBUGGING OUTPUT
//				System.out.println("Val: " + hash.getval_fromHash(idKey));  // DEBUGGING OUTPUT
				if (repl_or_app == REPLACE) {
					bw.write(hash.getval_fromHash(idKey));
				}
				else {		// append mode
					if (selfclose) {	// source is self-close (no data) on merge_tag
						bw.write(hash.getval_fromHash(idKey));
					}
					else {	// has data in source file
						String tag_src="", endtag_src, mid_src="";
						if (!samelineData) { // data NOT ON the same line as the begin/end-tag line
							// Only append "content" LINES between the begin/end merge-tag, so need to
							// search first 'newline' (assuming it's the matched merge-tag) and
							// 2nd to last 'newline' (assuming it's the match merge-end-tag).
							int pos_src_frstNL = copysrc.indexOf(newline);
							int pos_src_lastNL = copysrc.lastIndexOf(newline, copysrc.length()-3); // -3 just to pass the ending NL
							tag_src = copysrc.substring(0, pos_src_frstNL+1);		// "substring" ends at end_index-1, & we want to include NL
							endtag_src = copysrc.substring(pos_src_lastNL+1);
							mid_src = copysrc.substring(pos_src_frstNL+1, pos_src_lastNL+1);
						}
						else {  // data ON the same line as the begin/end-tag line
							int pos_src_tagRgtAngle = copysrc.indexOf(RgtAngle);
							int pos_src_endtagLftAngle = copysrc.lastIndexOf(LftAngle, copysrc.length()-3);
							tag_src = copysrc.substring(0, pos_src_tagRgtAngle+1)+ newline;
							endtag_src = copysrc.substring(pos_src_endtagLftAngle);	// substring to the end of line includes NL already
							mid_src = copysrc.substring(pos_src_tagRgtAngle+1, pos_src_endtagLftAngle) + newline;
						}
						String delta = hash.getval_fromHash(idKey);		
						int pos_delta_frstNL = delta.indexOf(newline);
						int pos_delta_lastNL = delta.lastIndexOf(newline, delta.length()-3); // -3 just to pass the ending NL
						// String tag_delta = delta.substring(0, pos_delta_frstNL+1);
						// String endtag_delta = delta.substring(pos_delta_lastNL+1);
						/* DEBUG ----
						System.out.println("Delta content = " + delta);
						System.out.println("Delta content -- tag_NL pos = " + pos_delta_frstNL + ", NL pos before 'endtag' = " + pos_delta_lastNL);
						*/
						String mid_delta = delta.substring(pos_delta_frstNL+1, pos_delta_lastNL+1);
						
						bw.write(tag_src);
						bw.write(mid_src);
						bw.write(mid_delta);
						bw.write(endtag_src);
					}
				}				
			}
		}
		catch (EOFException e_eof) {
			System.out.println("EOF Exception!   " + e_eof);
		}
		catch (IOException e) {
			System.out.println("IO Exception!   " +e);
		}
	}
	
	public void proc_source(BufferedReader br_source, BufferedWriter bw, boolean fullMatch, int repl_or_app) {	
		int ncases=0;  //character
		String line;
		
		// First search pattern is the idKey (tag + val + end_tag all in one line)
		String s_idKey = idKey_tag + "(.*)" + idKey_endtag;
	    Pattern p_idKey = Pattern.compile(s_idKey);
	    Pattern p_match = Pattern.compile(merge_tag);
	    Pattern p_match_end = Pattern.compile(merge_endtag);
	    Pattern p_match_selfclose = Pattern.compile(merge_tag_selfclose);

	    Matcher m_idKey, m_match, m_match_end, m_match_selfclose;
	    
	    String idKey="";
	    String preserve="";	// save lines between merge tag & idKey tag if merge tag comes up before idKey tag
	    String copysrc="";	// save data of merge tag in source in case not finding it in delta

	    boolean got_id = false;
	    boolean start_match = false;
	    boolean got_match = false;
	    boolean match_before_id = false;
		boolean selfclose = false;
		boolean samelineData = false;
		
		int pos_tag_rightangle, pos_endtag_leftangle;
	    
		try {
			while ((line = br_source.readLine()) != null)  {
				if (!got_id) {			// not yet read to "idKey"
					m_idKey = p_idKey.matcher(line);
					if (m_idKey.find()) {	// find "idKey"
						idKey = m_idKey.group(1);
						got_id = true;
						if (got_match && match_before_id) {	// had "merge tag" element before "idKey"
							write_merge_block(bw, fullMatch, idKey, copysrc, repl_or_app, selfclose, samelineData);					
							bw.write(preserve);		// write everything saved after "merge tag" block
							bw.write(line); bw.newLine();	// write "idKey" line
						
							ncases++;
							preserve = "";		// reset for next obj, finish writing for this obj
							copysrc = "";
							got_id = false;	
							start_match = false;	
							got_match = false;	// signal -- no more line-accumulation
							selfclose = false;
							samelineData = false;
							idKey = "";
						}
						else {	// write out the "idKey" line & continue searching for "merge tag"							
							if (!match_before_id)
								got_match = false;		// turn off (reset) for new case
							bw.write(line); bw.newLine();
						}
						continue;
					}
					else {	// line doesn't contain "idKey", but may have "merge tag" first
						
						if (start_match && !got_match) {	// separately store all lines inside source's "merge tag" block
							m_match_end = p_match_end.matcher(line);							
							if (m_match_end.find()) { // mark if find the end of "merge tag" block
								got_match = true;								
							}
							copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block
							continue;
						}
						m_match = p_match.matcher(line);
						m_match_selfclose = p_match_selfclose.matcher(line);
						if (m_match.find()) {	// separately store all lines between source's "merge" bgn/end tag	
							start_match = true;
							if (ncases == 0 && !got_id)  // First case, see match before idKey
								match_before_id = true;
							// Check -- merge_endtag may be on the same line as merge_tag
							m_match_end = p_match_end.matcher(line);							
							if (m_match_end.find()) { // mark if find the end of "merge tag" block
								got_match = true;								
							}
							pos_tag_rightangle = line.indexOf(merge_tag) + (merge_tag.length() - 1);
							pos_endtag_leftangle = line.indexOf(merge_endtag);
							if (pos_endtag_leftangle - pos_tag_rightangle == 1) {
								selfclose = true;		// no data is equiv to self-close
							}
							else {
								samelineData = true;	// has data on the same line with begin/close tag
							}
							copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block		
							continue;
						}
						else if (m_match_selfclose.find()) { // Check -- "merge tag" may be self-closing
							selfclose = true;
							start_match = true;
							if (ncases == 0 && !got_id)  // First case, see match before idKey
								match_before_id = true;
							got_match = true;	
							copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block
							continue;
						}
						if (got_match && match_before_id) {	// had "merge tag" element before "idKey"
							preserve = preserve + line + "\n";	// accumulate lines between the two tags
						}
						else {	// not inside the "merge tag" group, write out the line & continue searching for "merge tag" or "idKey"
							bw.write(line); bw.newLine();
						}
					}
					continue;
				}
				else {	// got "idKey"
					
					if (!start_match && !got_match) {  // hasn't seen "merge tag" either		
						m_match = p_match.matcher(line);
						m_match_selfclose = p_match_selfclose.matcher(line);
						if (m_match.find()) {	// ignore all lines between the "merge" bgn/end tag	
							start_match = true;
							got_match = false;
							copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block
							if (ncases == 0)  // First case, see match before idKey
								match_before_id = false;
							// Check -- merge_endtag may be on the same line as the merge_tag
							m_match_end = p_match_end.matcher(line);
							if (m_match_end.find()) { // "merge" bgn/end tag on same line -- write out the hash data
								got_match = true;		// signal we're done merging current case
								pos_tag_rightangle = line.indexOf(merge_tag) + (merge_tag.length() - 1);
								pos_endtag_leftangle = line.indexOf(merge_endtag);
								if (pos_endtag_leftangle - pos_tag_rightangle == 1) {
									selfclose = true;		// no data is equiv to self-close
								}
								else {
									samelineData = true;	// has data on the same line with begin/close tag
								}
								write_merge_block(bw, fullMatch, idKey, copysrc, repl_or_app, selfclose, samelineData);
						
								ncases++;
								preserve = "";		// reset for next obj, finish writing for this obj
								copysrc = "";
								got_id = false;	
								start_match = false;
								selfclose = false;
								samelineData = false;
								idKey = "";							
							}
						}
						else if (m_match_selfclose.find()) { // Check -- "merge tag" may be self-closing
							selfclose = true;
							start_match = true;
							if (ncases == 0 && !got_id)  // First case, see match before idKey
								match_before_id = true;
							got_match = true;
							copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block
							write_merge_block(bw, fullMatch, idKey, copysrc, repl_or_app, selfclose, samelineData);				
							
							ncases++;
							preserve = "";		// reset for next obj, finish writing for this obj
							copysrc = "";
							got_id = false;	
							start_match = false;
							selfclose = false;
							samelineData = false;
							idKey = "";	
						}
						else {	// write out lines as we go
							bw.write(line); bw.newLine();
						}
						continue;
					}
					else if (start_match && !got_match){
						m_match_end = p_match_end.matcher(line);
						copysrc = copysrc + line + "\n";	// store all lines inside source's "merge tag" block
						if (m_match_end.find()) { // write out the hash data
							got_match = true;		// signal we're done merging current case
							write_merge_block(bw, fullMatch, idKey, copysrc, repl_or_app, selfclose, samelineData);
	
							ncases++;
							preserve = "";		// reset for next obj, finish writing for this obj
							copysrc = "";
							got_id = false;	
							start_match = false;
							selfclose = false;
							samelineData = false;
							idKey = "";							
						}
						continue;	 
					}
				}
			}

			System.out.println("Total " + ncases + " processed in the source file.");
		}
		catch (EOFException e_eof) {
			System.out.println("EOF Exception!   " + e_eof);
		}
		catch (IOException e) {
			System.out.println("IO Exception!   " +e);
		}
	}
}



