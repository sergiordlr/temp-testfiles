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
@WebServlet(value = "/insert")
public class InsertServlet extends HttpServlet {

    ArrayList<Player> list = new ArrayList<Player>();

    private RemoteCacheManager cacheManager;

    @Override
    public void init() {

        ConfigurationBuilder cfg = ClientConfiguration.create();

        cacheManager = new RemoteCacheManager(cfg.build());
    }
        
    protected void doGet(HttpServletRequest req, HttpServletResponse res) {
        doPost(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) {
        res.setContentType("text/html");
        String cacheName = req.getParameter("cache");
        String key = req.getParameter("key");
        String data = req.getParameter("data");

        PrintWriter out = null;
        try {
            out = res.getWriter();

            out.println("In cache " + cacheName); 

            final RemoteCache<String, String> cache = cacheManager.getCache(cacheName);

            cache.put(key, data);

            out.println("Inserted key [" + key + "] with data: " + data);
             
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
}
