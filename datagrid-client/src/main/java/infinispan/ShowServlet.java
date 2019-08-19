package infinispan;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;
import org.infinispan.client.hotrod.configuration.ConfigurationBuilder;
import org.infinispan.commons.api.CacheContainerAdmin;
import org.infinispan.commons.configuration.XMLStringConfiguration;


@SuppressWarnings("serial")
@WebServlet(value = "/show")
public class ShowServlet extends HttpServlet {


    private RemoteCacheManager cacheManager;
    private static final String USER = "test";
    private static final String PASSWORD = "changeme";

    @Override
    public void init() {

        String SVC_DNS_NAME =  System.getenv("HOTROD_SERVICE");
        String SVC_PORT =  System.getenv("HOTROD_SERVICE_PORT");
        String APP_NAME =  System.getenv("APP_NAME");

        System.out.println("APP " + APP_NAME);
        ConfigurationBuilder cfg = ClientConfiguration.create(SVC_DNS_NAME, SVC_PORT, APP_NAME, USER, PASSWORD);

        cacheManager = new RemoteCacheManager(cfg.build());
    }
        
    protected void doGet(HttpServletRequest req, HttpServletResponse res) {
        doPost(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) {
        res.setContentType("text/html");
        String cacheName = req.getParameter("cache");

        PrintWriter out = null;
        try {
            out = res.getWriter();

            out.println("In cache " + cacheName); 
            out.println("<br>");

            final RemoteCache<String, String> cache = cacheManager.getCache(cacheName);

            for (Map.Entry<String, String> entry : cache.entrySet()) {
                out.println(entry.getKey() + " : " + entry.getValue());
                out.println("<br>");
            }
             
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
}
