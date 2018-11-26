<%--
    Document   : index
    Created on : Oct 29, 2018, 4:09:07 PM
    Author     : racie
--%>

<%@page import="java.nio.charset.Charset"%>
<%@page import="java.io.InputStreamReader"%>
<%@page import="java.io.BufferedReader"%>
<%@page import="java.io.InputStream"%>
<%@page import="org.json.JSONException"%>
<%@page import="java.io.Reader"%>
<%@page import="org.json.JSONArray"%>
<%@page import="org.json.JSONObject"%>
<%@page import="java.net.URLConnection"%>
<%@page import="java.util.Collections"%>
<%@page import="java.util.Comparator"%>
<%@page import="java.util.TreeSet"%>
<%@page import="java.util.SortedSet"%>
<%@page import="java.util.Arrays"%>
<%@page import="org.jsoup.nodes.Document"%>
<%@page import="java.net.MalformedURLException"%>
<%@page import="java.net.HttpURLConnection"%>
<%@page import="java.net.URL"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.UnsupportedEncodingException"%>
<%@page import="org.jsoup.nodes.Element"%>
<%@page import="org.jsoup.select.Elements"%>
<%@page import="java.net.URLDecoder"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="org.jsoup.Jsoup"%>
<%@page import="org.apache.commons.lang3.StringUtils"%>
<%!
    public class SearchResults {

        String title;
        String URL;
        int index;
        Long fileSize;

        SearchResults(String title, String URL) {
            this.title = title;
            this.URL = URL;
        }

        SearchResults(String title, String URL, Long downloadTime) {
            this.title = title;
            this.URL = URL;
            this.fileSize = downloadTime;
        }
    }

    public class Movie {

        String title;
        String year;
        String poster;
        ArrayList<SearchResults> search;
        boolean canSearch = false;

        Movie(String title, String year, String poster) {
            this.title = title;
            this.year = year;
            this.poster = poster;
        }

        void setSearch(ArrayList<SearchResults> search) {
            this.search = search;
            canSearch = true;
        }

    }

    class Sortbynumb implements Comparator<SearchResults> {

        public int compare(SearchResults a, SearchResults b) {
            return b.index - a.index;
        }
    }

    ArrayList<SearchResults> search(String query) {
        ArrayList<SearchResults> contents = new ArrayList();
        String google = "http://www.google.com/search?q=";
        String search = "intext:\"" + query + "\" (.avi|.m4v|.mov|.mp4|.wmv|.bytheeye) -inurl:(htm|html|php) intitle:\"index.of./\"";
        String charset = "UTF-8";
        String userAgent = "ExampleBot 1.0 (+http://example.com/bot)";

        Elements links = new Elements();
        try {
            links = Jsoup.connect(google + URLEncoder.encode(search, charset)).userAgent(userAgent).get().select(".g>.r>a");
        } catch (UnsupportedEncodingException ex) {
        } catch (IOException px) {
        }

        for (Element link : links) {
            String title = link.text();
            String url = link.absUrl("href"); // Google returns URLs in format "http://www.google.com/url?q=<url>&sa=U&ei=<someKey>".

            try {
                url = URLDecoder.decode(url.substring(url.indexOf('=') + 1, url.indexOf('&')), "UTF-8");
            } catch (UnsupportedEncodingException ex) {
            }

            if (!url.startsWith("http")) {
                continue; // Ads/news/etc.
            }

            //System.out.println("Title: " + title);
            //System.out.println("URL: " + url);
            contents.add(new SearchResults(title, url));
        }
        return contents;
    }

    public static boolean pingURL(String url, int timeout) {
        url = url.replaceFirst("^https", "http"); // Otherwise an exception may be thrown on invalid SSL certificates.

        try {
            HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
            connection.setConnectTimeout(timeout);
            connection.setReadTimeout(timeout);
            connection.setRequestMethod("HEAD");
            int responseCode = connection.getResponseCode();
            return (200 <= responseCode && responseCode <= 399);
        } catch (IOException exception) {
            return false;
        }
    }

    ArrayList<SearchResults> remove404s(ArrayList<SearchResults> srl) {
        ArrayList<SearchResults> cleaned = new ArrayList();
        for (SearchResults sr : srl) {
            if (pingURL(sr.URL, 400)) {
                cleaned.add(sr);
            }
        }
        return cleaned;
    }

    public static boolean stringContainsItemFromList(String inputStr, String[] items) {
        return (StringUtils.indexOfAny(inputStr, items) > -1);
    }

    ArrayList<SearchResults> getFiles(ArrayList<SearchResults> srl, String key) {
        ArrayList<SearchResults> files = new ArrayList();
        String[] keys = key.split(" ");
        System.out.println("");
        System.out.println("Bad URLs: ");
        for (SearchResults sr : srl) {
            String text = "";
            String URL = "";
            try {
                Document doc = Jsoup.connect(sr.URL).get();
                Elements elements = doc.select("a");
                for (Element element : elements) {
                    URL = element.absUrl("href");
                    text = element.text();

                    //CHECKS IF ELEMNT GOT FROM DOCUMENT IS APPLICABLE
                    if (stringContainsItemFromList(text, keys)) {
                        if (URL.contains(".mp4") || URL.contains(".mkv") || URL.contains(".avi")) {
                            if (!URL.contains("archive.org")) {
                                //long size = new URL(URL).openConnection().getContentLength();
                                //long size = getFileSize(new URL(URL));
                                files.add(new SearchResults(text, URL));
                            }
                        }
                    }
                }
            } catch (IOException e) {
                System.out.println(sr.URL);
            }
        }

        return files;
    }

    ArrayList<SearchResults> sortList(ArrayList<SearchResults> srl, String key) {
        String[] keys = key.split(" ");
        for (SearchResults sr : srl) {
            int value = 0;
            for (String k : keys) {
                if (sr.title.contains(k)) {
                    value++;
                }
                if (sr.URL.contains(k)) {
                    value++;
                }
            }
            if (sr.URL.contains("mp4")) {
                value++;
            }
            if (sr.title.contains("720") || sr.title.contains("1080")) {
                value++;
            }
            if (sr.title.startsWith(keys[0])) {
                value++;
            }
            if (sr.title.contains("Trailer") || sr.title.contains("trailer")) {
                value--;
                value--;
            }
            sr.index = value;
        }

        Collections.sort(srl, new Sortbynumb());

        System.out.println("");
        System.out.println("Sorted List: ");
        for (SearchResults srp : srl) {
            //System.out.println(srp.fileSize + " : " + srp.index + " : " + srp.title);
            System.out.println(srp.index + ": " + srp.title);
        }

        return srl;
    }

    private static String readAll(Reader rd) throws IOException {
        StringBuilder sb = new StringBuilder();
        int cp;
        while ((cp = rd.read()) != -1) {
            sb.append((char) cp);
        }
        return sb.toString();
    }

    public static JSONObject readJsonFromUrl(String url) throws IOException, JSONException {
        InputStream is = new URL(url).openStream();
        try {
            BufferedReader rd = new BufferedReader(new InputStreamReader(is, Charset.forName("UTF-8")));
            String jsonText = readAll(rd);
            JSONObject json = new JSONObject(jsonText);
            return json;
        } finally {
            is.close();
        }
    }

    ArrayList<Movie> getOMDMovies(String query, int pageNum) throws IOException {
        ArrayList<Movie> movies = new ArrayList();

        query = query.replace(" ", "+");

        JSONObject Jobject = readJsonFromUrl("http://www.omdbapi.com/?apikey=16f77a27&s=" + query + "&page=" + pageNum);
        if (Jobject.getString("Response").equals("True")) {
            JSONArray Jarray = Jobject.getJSONArray("Search");

            for (int i = 0; i < Jarray.length(); i++) {
                JSONObject object = Jarray.getJSONObject(i);
                String title = "";
                String plot = "";
                String poster = "";

                if (object.getString("Title") != null) {
                    title = object.getString("Title");
                }
                if (object.getString("Year") != null) {
                    plot = object.getString("Year");
                }
                if (object.getString("Poster") != null) {
                    poster = object.getString("Poster");
                }
                movies.add(new Movie(title, plot, poster));
            }
        }
        return movies;
    }

    ArrayList<SearchResults> getFilesAndSort(String key) {
        ArrayList<SearchResults> files = new ArrayList();
        ArrayList<SearchResults> spr = search(key);

        System.out.println("");
        System.out.println("Looking for data for search \"" + key + "\": ");
        for (SearchResults sr : spr) {
            System.out.println(sr.title);
        }

        files = getFiles(spr, key);
        System.out.println("");
        System.out.println("List of URLS: ");
        for (SearchResults sr : files) {
            System.out.println(sr.URL);
        }

        files = sortList(files, key);

        return files;
    }


%>
<%
    //ArrayList<SearchResults> files = new ArrayList();
    ArrayList<Movie> movies = new ArrayList();
    int currentPage = 1;
    int maxIndex = 5;
    int startIndex = 0;
    String previous = "visibility: hidden";
    String next = "visibility: hidden";
    String currentURL = request.getRequestURI();
    String key = "";

    if (request.getParameter("q") != null) {
        key = request.getParameter("q");

        //GETS IMDB STUFF
        movies = getOMDMovies(request.getParameter("q"), currentPage);
        System.out.println("");
        System.out.println("Search Results from IMDB:");
        for (Movie movie : movies) {
            System.out.println(movie.title);
        }

        for (int i = 0; i < movies.size(); i++) {
            //CHECKS IF FILES ARE ALREADY AVALIABLE
            Movie movie = movies.get(i);
            if (session.getAttribute(movie.title) != null) {
                ArrayList<SearchResults> files = (ArrayList<SearchResults>) session.getAttribute(movie.title);
                System.out.println("");
                try {
                    movies.get(i).setSearch(files);
                    String title = movies.get(i).search.get(0).title;
                    System.out.println("Grabbed \"" + movie.title + "\" from session");
                } catch (Exception ex) {
                    System.out.println("!!! \"" + movie.title + "\" INVALIDATED!!!");
                    session.removeAttribute(movie.title);
                    movies.get(i).setSearch(new ArrayList());
                }
            }
        }

        //GETS FILES FOR INT F
        if (request.getParameter("f") != null) {
            String[] splitLoads = request.getParameter("f").split(",");
            for (String index : splitLoads) {
                int parsedIndex = Integer.parseInt(index);
                try {
                    if (movies.get(parsedIndex) != null) {
                        try {
                            if (movies.get(parsedIndex).search.size() == 0) {
                                movies.get(parsedIndex).setSearch(getFilesAndSort(movies.get(parsedIndex).title));
                                session.setAttribute(movies.get(parsedIndex).title, movies.get(parsedIndex).search);
                            }
                        } catch (NullPointerException ex) {
                            movies.get(parsedIndex).setSearch(getFilesAndSort(movies.get(parsedIndex).title));
                            session.setAttribute(movies.get(parsedIndex).title, movies.get(parsedIndex).search);
                        }
                    }
                } catch (IndexOutOfBoundsException ex) {
                    System.out.println("Couldn't get movies for index: " + parsedIndex);
                    maxIndex = 0;
                }
            }
        }

        //Checks if search array exists for movies
        for (int i = 0; i < movies.size(); i++) {
            try {
                ArrayList<SearchResults> search = movies.get(i).search;
                String text = search.get(0).URL;
            } catch (Exception ex) {
                movies.get(i).canSearch = false;
            }
        }

        //HANDLES MULTIPLE PAGES
        if (request.getParameter("p") != null) {
            try {
                int index = Integer.parseInt(request.getParameter("p"));
                if (index != 1) {
                    currentPage = index;
                    maxIndex = (index * 10) / 2;
                    startIndex = ((index - 1) * 10) / 2;
                    previous = "visibility: visible";
                }
            } catch (Exception ex) {
            }
        }
        if (movies.size() > maxIndex) {
            next = "visibility: visible";
        } else {
            maxIndex = movies.size();
        }

        //IF NO RESULTS ARE FOUND
        if (movies.size() == 0) {
            //movies.add(new Movie("Movie not found"));
            //maxIndex++;
        }
    } else {
        //IF THERE IS NO QUERY
        maxIndex = 0;
    }
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>

    <head>
        <meta charset="utf-8">
        <meta http-equiv="x-ua-compatible" content="ie=edge">
        <meta name="viewport" content="width=device-width, initial-scale=0.6, maximum-scale=0.6, user-scalable=no" />
        <title>CatFlix</title>
        <link href="https://vjs.zencdn.net/7.2.3/video-js.css" rel="stylesheet">
        <script src="https://vjs.zencdn.net/ie8/ie8-version/videojs-ie8.min.js"></script>
        <script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>
        <script src='https://www.google.com/recaptcha/api.js'></script>
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.5.0/css/all.css" integrity="sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU" crossorigin="anonymous">
        <link rel="apple-touch-icon" sizes="180x180" href="/CatFlix/assets/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/CatFlix/assets/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/CatFlix/assets/favicon-16x16.png">
        <link rel="manifest" href="/CatFlix/assets/site.webmanifest">
        <link rel="mask-icon" href="/CatFlix/assets/safari-pinned-tab.svg" color="#5bbad5">
        <link rel="shortcut icon" href="/CatFlix/assets/favicon.ico">
        <meta name="msapplication-TileColor" content="#da532c">
        <meta name="msapplication-config" content="/CatFlix/assets/browserconfig.xml">
        <meta name="theme-color" content="#ffffff">
        <script>
            function onSubmit(token) {
                document.getElementById("search").submit();
            }
        </script>
        <link rel="stylesheet" href="assets/main.css?v=32">
    </head>

    <body>
        <div id="particles-js"></div>
        <div id="wrapper">
            <div id="center">
                <h1><a href="index.jsp">CatFlix</a></h1>
                <form id="search" class="form-wrapper cf" action="" method="get">
                    <input name="q" type="text" placeholder="Search here..." value="<%=key%>" required>
                    <button class="g-recaptcha" data-sitekey="6Ld32XcUAAAAAH3Xxlz-7gvfvvrW1pDfrCCmVlGr" data-callback='onSubmit'>Search</button>
                </form>
                <%
                    for (int currentIndex = startIndex; currentIndex < maxIndex; currentIndex++) {
                %>
                <div id="video-wrapper">
                    <img src="<%=movies.get(currentIndex).poster%>" style="float: left; width: 200px; height: 300px;">
                    <h2><%=movies.get(currentIndex).title%></h2>
                    <%
                        if (movies.get(currentIndex).canSearch == true) {
                    %>
                    <div style="margin-left: 220px; margin-top: 10px; height: 260px; overflow-y: auto; box-shadow: 0 0 5px black;">
                        <%
                            int index = 0;
                            for (SearchResults result : movies.get(currentIndex).search) {
                                index++;

                        %>
                        <button id="something<%=index%>" style="display: block; text-decoration: none; color: white; font-size: 14px; background-color: Transparent; cursor: pointer; overflow: hidden; outline: none; border: none; box-shadow: 0 0 2px black; margin-bottom: 5px;">
                            <a target="_blank" rel="noopener noreferrer" style="text-decoration: none; color: grey; font-size: 14px; background-color: Transparent; cursor: pointer;" href="<%=result.URL%>" download>
                                <i class="fas fa-file-download"></i>
                            </a> <%=result.title%>
                        </button>
                        <script>
                            document.getElementById('something<%=index%>').addEventListener('click', function () {
                                var myPlayer = videojs('my-video<%=currentIndex%>');
                                myPlayer.src({type: 'video/mp4', src: "<%=result.URL%>"});
                                document.getElementById('something<%=index%>').style.color = "grey";
                            });
                        </script>
                        <%                            }

                        %>
                    </div>
                    <video
                        style="margin-top: 10px;"
                        id="my-video<%=currentIndex%>"
                        class="video-js vjs-default-skin vjs-big-play-centered"
                        controls
                        preload="metadata"
                        width="670" height="390"
                        data-setup='{ "techOrder": ["html5"], "sources": [{ "type": "video/mp4", "src": "<%=movies.get(0).search.get(0).URL%>"}] }'
                        >
                    </video>
                    <%                    } else {
                    %>
                    <a id="search<%=currentIndex%>" href="<%=currentURL%>?q=<%=key%>&f=<%=currentIndex%>&p=<%=currentPage%>" style="border-radius: 25px; display: inline-block; margin-top: 100px; margin-left: 165px; background-color: #4CAF50; border: none; color: white; padding: 15px 32px; text-align: center; text-decoration: none; font-size: 16px;"><i id="icon<%=currentIndex%>" class="fas fa-search"></i> Search</a>
                    <script>
                        document.getElementById('search<%=currentIndex%>').addEventListener('click', function () {
                            var button = document.getElementById('search<%=currentIndex%>');
                            var icon = document.getElementById('icon<%=currentIndex%>');
                            button.style.backgroundColor = "#013220";
                            icon.className = "fa fa-spinner fa-spin";
                        });
                    </script>
                    <%                    }
                    %>
                </div>
                <%                    }
                %>
                <a href="<%=currentURL%>?q=<%=key%>&p=<%=currentPage - 1%>" class="butt previous" style="<%=previous%>">&laquo; Previous</a>
                <a href="<%=currentURL%>?q=<%=key%>&p=<%=currentPage + 1%>" class="butt next" style="<%=next%>">Next &raquo;</a>
                <footer>
                    Made with &hearts; by Trev
                </footer>

            </div>
        </div>


        <script src="https://vjs.zencdn.net/7.2.3/video.js"></script>
        <script type="text/javascript" src="assets/dots.js?v=3"></script>
    </body>

</html>
