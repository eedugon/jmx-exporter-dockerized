package org.munin;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Map.Entry;

import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;

public class Configuration 
{
private Properties graph_properties = new Properties();
private Map<String, FieldProperties> fieldMap = new HashMap<String,FieldProperties>();
private List<FieldProperties> fields = new ArrayList<FieldProperties>();

public class FieldProperties extends Properties
{
	private static final long serialVersionUID = 1L;
	private ObjectName jmxObjectName;
	private String jmxAttributeName, jmxAttributeKey, fieldname;
	private static final String JMXOBJECT = "jmxObjectName";
	private static final String JMXATTRIBUTE = "jmxAttributeName";
	private static final String JMXATTRIBUTEKEY = "jmxAttributeKey";
	public FieldProperties(String fieldname) {
		this.fieldname = fieldname;
	}
	public String getJmxAttributeKey() {
		return jmxAttributeKey;
	}
	public String getJmxAttributeName() {
		return jmxAttributeName;
	}

	public ObjectName getJmxObjectName() {
		return jmxObjectName;
	}

	@Override
	public String toString() {
		return fieldname;
	}
	public void set(String key, String value) throws MalformedObjectNameException, NullPointerException {
		if(JMXOBJECT.equals(key)){
			if(jmxObjectName!=null)
				throw new IllegalStateException(JMXOBJECT+" already set for "+this);
			jmxObjectName = new ObjectName(value);
		}
		else if(JMXATTRIBUTE.equals(key)){
			if(jmxAttributeName!=null)
				throw new IllegalStateException(JMXATTRIBUTE+" already set for "+this);
			jmxAttributeName = value;
		}
		else if(JMXATTRIBUTEKEY.equals(key)){
			if(jmxAttributeKey!=null)
				throw new IllegalStateException(JMXATTRIBUTEKEY+" already set for "+this);
			jmxAttributeKey = value;
		}
		else{
			put(key, value);
		}
	}
	public void report(PrintStream out) {
		for(Iterator it = entrySet().iterator();it.hasNext();){
			Map.Entry entry = (Entry) it.next();
			out.println(fieldname+'.'+entry.getKey() + " "+entry.getValue());
		}		
	}
	public String getFieldname() {
		return fieldname;
	}
	
}

private Configuration(){}

public static Configuration parse(String config_file) throws IOException, MalformedObjectNameException, NullPointerException
{
	BufferedReader reader = new BufferedReader(new FileReader(config_file));
	Configuration configuration = new Configuration();
	try{
		while(true){
			String s = reader.readLine();
			if(s==null)
				break;
			if(!s.startsWith("%") && s.length()>5 && !s.startsWith(" ")){
				configuration.parseString(s);
			}
		}
	}finally{
		reader.close();
	}	

	return configuration;
	
}

private void parseString(String s) throws MalformedObjectNameException, NullPointerException {
	String[] nameval = s.split(" ", 2);
	if(nameval[0].indexOf('.')>0){ // field prop
		String name = nameval[0];
		String fieldname = name.substring(0, name.lastIndexOf('.'));
		if(!fieldMap.containsKey(fieldname)){
			FieldProperties field = new FieldProperties(fieldname);
			fieldMap.put(fieldname, field);
			fields.add(field);
		}
		FieldProperties field = fieldMap.get(fieldname);
		String key = name.substring(name.lastIndexOf('.')+1);
		field.set(key, nameval[1]);
	}else{ // graph prop
		graph_properties.put(nameval[0], nameval[1]);
	}

	
}

public Properties getGraphProperties() {
	return graph_properties;
}

public void report(PrintStream out) {
	for(Iterator it = graph_properties.entrySet().iterator();it.hasNext();){
		Map.Entry entry = (Entry) it.next();
		out.println(entry.getKey() + " "+entry.getValue());
	}
	
	for(FieldProperties field : fields){
		field.report(out);
	}
	
}

public List<FieldProperties> getFields() {
	return fields;
}



}
