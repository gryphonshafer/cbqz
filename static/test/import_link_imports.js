var links = document.getElementsByTagName("link");
for ( var i = 0; i < links.length; i++ ) {
    var req = new XMLHttpRequest();
    req.overrideMimeType("text/plain");
    req.addEventListener( "load", function () {
        if ( this.responseURL.search("\.js$") != -1 ) {
            var element       = document.createElement("script");
            element.innerHTML = this.responseText;
            document.body.appendChild(element);
        }
        else {
            var element       = document.createElement("div");
            element.innerHTML = this.responseText;
            var nodes         = element.childNodes;

            for ( var j = 0; j < nodes.length; j++ ) {
                if ( nodes[j].nodeType == 1 ) {
                    if ( nodes[j].nodeName == "SCRIPT" && nodes[j].type == "text/javascript" ) {
                        var script = document.createElement("script");
                        script.innerHTML = nodes[j].innerHTML;
                        document.body.appendChild(script);
                    }
                    else {
                        document.body.appendChild( nodes[j] );
                    }
                }
            }
        }
    } );
    req.open( "GET", links[i].href );
    req.send();
}
