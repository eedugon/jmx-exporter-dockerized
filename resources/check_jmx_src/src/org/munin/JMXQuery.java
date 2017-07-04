package org.munin;

import java.io.IOException;
import java.text.NumberFormat;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import javax.management.Attribute;
import javax.management.InstanceNotFoundException;
import javax.management.IntrospectionException;
import javax.management.MBeanAttributeInfo;
import javax.management.MBeanInfo;
import javax.management.MBeanServerConnection;
import javax.management.ObjectName;
import javax.management.ReflectionException;
import javax.management.openmbean.CompositeDataSupport;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;

import org.munin.Configuration.FieldProperties;


/**
 * 
 * JMXQuery is used for local or remote request of JMX attributes
 * It requires JRE 1.5 to be used for compilation and execution.
 * Look method main for description how it can be invoked.
 * 
 */
public class JMXQuery {

	private String url;
	private JMXConnector connector;
	private MBeanServerConnection connection;
	private Configuration config;
	
	
	public JMXQuery(String url) {
		this.url = url;
	}

	private void connect() throws IOException
	{
         JMXServiceURL jmxUrl = new JMXServiceURL(url);
         connector = JMXConnectorFactory.connect(jmxUrl);
         connection = connector.getMBeanServerConnection();
	}
	

	

	private void list() throws IOException, InstanceNotFoundException, IntrospectionException, ReflectionException {
		if(config==null)
			listAll();
		else
			listConfig();
	}

	private void listConfig() {
		for(FieldProperties field : config.getFields()){
			try {
				Object value = connection.getAttribute(field.getJmxObjectName(), field.getJmxAttributeName());
				output(field.getFieldname(), value, field.getJmxAttributeKey());
			} catch (Exception e) {
				System.err.println("Fail to output "+field+":"+e.getMessage());
			}
		}
	}

	private void output(String name, Object attr, String key) {
		if(attr instanceof CompositeDataSupport){
			CompositeDataSupport cds = (CompositeDataSupport) attr;
			if(key==null)
				throw new IllegalArgumentException("Key is null for composed data "+name);
			System.out.println(name+".value "+format(cds.get(key)));
		}else
			System.out.println(name+".value "+format(attr));
	}

	private void output(String name, Object attr) {
		if(attr instanceof CompositeDataSupport){
			CompositeDataSupport cds = (CompositeDataSupport) attr;
			for(Iterator it = cds.getCompositeType().keySet().iterator();it.hasNext();){
				String key = it.next().toString();
				System.out.println(name+"."+key+".value "+format(cds.get(key)));
			}
		}else
			System.out.println(name+".value "+format(attr));
	}

	@SuppressWarnings("unchecked")
	private void listAll() throws IOException, InstanceNotFoundException, IntrospectionException, ReflectionException {
		Set<ObjectName> mbeans = connection.queryNames(null, null);
		for(ObjectName name : mbeans){
			MBeanInfo info =  connection.getMBeanInfo(name);
			MBeanAttributeInfo[] attrs = info.getAttributes();
			String[] attrNames = new String[attrs.length];
			for(int i=0;i<attrs.length;i++){
				attrNames[i] = attrs[i].getName();
			}
			try {
				List<Attribute> attributes = connection.getAttributes(name, attrNames);
				for(Attribute attribute: attributes){	
					output(name.getCanonicalName()+"%"+attribute.getName(),attribute.getValue());
				}				
			} catch (Exception e) {
				System.err.println("error getting "+name+":"+e.getMessage());
			}

		}
	}
	
	private String format(Object value) {
		if(value==null)
			return null;
		else if(value instanceof String)
			return (String) value;
		else if(value instanceof Number){
			NumberFormat f = NumberFormat.getInstance();
			f.setMaximumFractionDigits(2);
			f.setGroupingUsed(false);
			return f.format(value);
		}else if(value instanceof Object[]){
			return Arrays.toString((Object[])value);
		}
		return value.toString();
	}

	private void disconnect() throws IOException {
        connector.close();
	}
	
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if(args.length<1)
			System.err.println("Usage of program is:\n"+
					"java -cp jmxquery.jar org.munin.JMXQuery <URL> [[<config file>] config]\n"+
					", where <URL> is a JMX URL, for example: service:jmx:rmi:///jndi/rmi://HOST:PORT/jmxrmi\n"+
					"When invoked with the config file (look examples folder) - operates as Munin plugin with the proviuded configuration\n"+
					"Without options just fetches all JMX attributes using provided URL");
		
		String url = args[0];
		String config_file = args.length > 1 ? args[1] : null;
		boolean toconfig = args.length>2 && args[2].equalsIgnoreCase("config");
		
		if(toconfig){
			try {
				Configuration.parse(config_file).report(System.out);
			} catch (Exception e) {
				System.err.println(e.getMessage()+" reading "+ config_file);
				System.exit(1);
			} 
		}else{
			JMXQuery query = new JMXQuery(url);
			try{
				query.connect();
				if(config_file!=null)
					query.setConfig(Configuration.parse(config_file));
				query.list();
			}catch(Exception ex){
				System.err.println(ex.getMessage()+" querying "+ url);
				ex.printStackTrace();
				System.exit(1);
			}finally{
				try {
					query.disconnect();
				} catch (IOException e) {
					System.err.println(e.getMessage()+" closing "+ url);
				}
			}			
		}
		
	}

	private void setConfig(Configuration configuration) {
		this.config = configuration;
	}

	public Configuration getConfig() {
		return config;
	}

}
