package infinispan;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.UUID;

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
@WebServlet(value = "/dgcache")
public class DgCacheServlet extends HttpServlet {

    ArrayList<Player> list = new ArrayList<Player>();

    private RemoteCacheManager cacheManager;
    private RemoteCache<String, Object> cache;
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
        cache = cacheManager.getCache("default");

        System.out.println("Loaded Cache " + cache);
    }
        
    protected void doGet(HttpServletRequest req, HttpServletResponse res) {
        doPost(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) {
        res.setContentType("text/html");
        String cacheName = req.getParameter("name");

        PrintWriter out = null;
        try {
            out = res.getWriter();

            out.println("Creaging cache..."); 

            XMLStringConfiguration xml = new XMLStringConfiguration(String.format(
               "<infinispan>" +
                  "<cache-container>" +
                     "<distributed-cache name=\"%1$s\">" +
                        "<persistence passivation=\"false\">" +
                           "<file-store " +
                              "shared=\"false\" " +
                              "fetch-state=\"true\" " +
                              "path=\"${jboss.server.data.dir}/datagrid-infinispan/%1$s\"" +
                           "/>" +
                        "</persistence>" +
                     "</distributed-cache>" +
                  "</cache-container>" +
               "</infinispan>",
               cacheName
            ));
      
            final RemoteCache<?, ?> createdCache = cacheManager.administration()
               .withFlags(CacheContainerAdmin.AdminFlag.PERMANENT)
               .getOrCreateCache(cacheName, xml);

            out.println("Created cache [" + cacheName + "]");
             
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
}
