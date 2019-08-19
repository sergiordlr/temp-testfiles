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

@SuppressWarnings("serial")
@WebServlet(value = "/create")
public class CreateCacheServlet extends HttpServlet {

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
        //String  =  System.getenv("HOTROD_SERVICE_PORT")

        System.out.println("APP " + APP_NAME);
        ConfigurationBuilder cfg = ClientConfiguration.create(SVC_DNS_NAME, SVC_PORT, APP_NAME, USER, PASSWORD);

        //builder.addServer().host()
        //        .port(Integer.parseInt));
        cacheManager = new RemoteCacheManager(cfg.build());
        cache = cacheManager.getCache("default");
        //cache = cacheManager.getCache();

        System.out.println("Loaded Cache " + cache);
    }
        
    protected void doGet(HttpServletRequest req, HttpServletResponse res) {
        doPost(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) {
        // Here the request is put in asynchronous mode
        res.setContentType("text/html");




        String cacheName = req.getParameter("name");

        // Actual logic goes here.
        PrintWriter out = null;
        try {
            out = res.getWriter();

            out.println("Creaging cache..."); 

            RemoteCache<?, ?> createdCache = cacheManager.administration()
                                                   .withFlags(CacheContainerAdmin.AdminFlag.PERMANENT)
                                                   .getOrCreateCache(cacheName, "default"); 
            out.println("Created cache [" + cacheName + "]");


             
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }

    }
}
