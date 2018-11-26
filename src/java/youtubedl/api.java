/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package youtubedl;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.google.gson.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 *
 * @author spotdemo4
 */
public class api extends HttpServlet {
    final String path = "C:\\Users\\racie\\Desktop\\projects\\CatFlix\\build\\web\\dl\\";
    
    public static String execCmd(String cmd) throws java.io.IOException {
        java.util.Scanner s = new java.util.Scanner(Runtime.getRuntime().exec(cmd).getInputStream()).useDelimiter("\\A");
        return s.hasNext() ? s.next() : "";
    }
    
    class Video {
        
        public boolean success;
        public String givenURL;
        public String title;
        public String id;
        public String ext;
        public int duration;
        public String downloadURL;
        
        Video(String URL){
            try{
                String json = execCmd("youtube-dl.exe -s -J \"" + URL + "\"");
                JsonObject obj = new JsonParser().parse(json).getAsJsonObject();
                
                this.givenURL = URL;
                this.title = obj.get("title").getAsString();
                this.id = obj.get("id").getAsString();
                this.ext = obj.get("ext").getAsString();
                this.duration = obj.get("duration").getAsInt();
                
                if(this.duration > 1200){
                    this.success = false;
                } else {
                    this.success = true;
                }
                
            } catch (Exception ex){
                this.success = false;
                ex.printStackTrace();
            }
        }
        
        void downloadVideo(){
            try{
                if(duration > 0){
                    String run = execCmd("youtube-dl -o \"" + path + id + "." + ext + "\" " + givenURL);
                    this.downloadURL = "http://localhost:8084/CatFlix/dl/" + id + "." + ext;
                } else {
                    this.success = false;
                }
            } catch(Exception ex){
                this.success = false;
                ex.printStackTrace();
            }
        }
        
    }

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    DownloadVideo object = new DownloadVideo(); 
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String URL = request.getParameter("url");
        
        
        Video devs = new Video(URL);
        if(devs.success == true){
            System.out.println(devs.title);
            devs.downloadVideo();
        }
        
        response.setContentType("application/json;charset=UTF-8");
        if(devs.success == true){
            String vidJson = new Gson().toJson(devs);
            try (PrintWriter out = response.getWriter()) {
                out.print(vidJson);
            }
        } else {
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"success\":\"false\"}");
            }
        }
        
        /*
        if(URL.equals("start")){
            object.start();
            System.out.println("Started");
        } else {
            System.out.println(object.getProgress());
        }
        */
        
        
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}

class DownloadVideo extends Thread 
{ 
    public int progress = 0;
    
    @Override
    public void run() 
    { 
        try
        { 
            // Displaying the thread that is running 
            System.out.println ("Thread " + 
                  Thread.currentThread().getId() + 
                  " is running"); 
            for(int i = 0; i < 100; i++){
                progress = progress + 1;
                Thread.sleep(1000);
            }
        } 
        catch (Exception e) 
        { 
            // Throwing an exception 
            System.out.println ("Exception is caught"); 
        } 
    } 
    
    int getProgress(){
        return progress;
    }
} 
