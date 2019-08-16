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

@SuppressWarnings("serial")
@WebServlet(value = "/test")
public class TestServlet extends HttpServlet {

    ArrayList<Player> list = new ArrayList<Player>();

    private RemoteCacheManager cacheManager;
    private RemoteCache<Object, Object> cache;
    private static final String USER = "test";
    private static final String PASSWORD = "changeme";

    @Override
    public void init() {

        String SVC_DNS_NAME =  System.getenv("HOTROD_SERVICE");
        String APP_NAME = SVC_DNS_NAME;
        //String  =  System.getenv("HOTROD_SERVICE_PORT")

        ConfigurationBuilder cfg = ClientConfiguration.create(SVC_DNS_NAME, APP_NAME, USER, PASSWORD);

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

        String name = req.getParameter("name");
        String surname = req.getParameter("surname");
        String teamName = req.getParameter("teamname");

        // Actual logic goes here.
        PrintWriter out = null;
        try {
            out = res.getWriter();

            Player player = new Player();
            player.setName(name);
            player.setSurname(surname);
            player.setTeamName(teamName);
            String randomId = UUID.randomUUID().toString();
                        out.println("Added Player"); 
            //cache.put(randomId.getBytes(), player);
            //cache.put("my-id".getBytes(), "myvalue");

            out.println("Added Player ID[" + randomId + "]: " + cache.get(randomId));

            for ( Object k: cache.keySet()){
                out.println("Key [" + k.getClass() + "] " );
            }
             
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }

    }
}
