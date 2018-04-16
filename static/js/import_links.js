( function () {
    var node_blocks   = {};
    var link_elements = [].slice.call( document.getElementsByTagName("link") ).filter( function (this_link) {
        return this_link.rel == "import";
    } );

    for ( var i = 0; i < link_elements.length; i++ ) {
        initiate( link_elements[i].href );
    }

    function initiate (url) {
        var req = new XMLHttpRequest();
        req.overrideMimeType("text/plain");
        req.addEventListener( "load", function () {
            var nodes_to_add = [];

            if ( this.responseURL.search(/\.js$|\.js\?/) != -1 ) {
                var element       = document.createElement("script");
                element.innerHTML = this.responseText;
                nodes_to_add.push(element);
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
                            nodes_to_add.push(script);
                        }
                        else {
                            nodes_to_add.push( nodes[j] );
                        }
                    }
                }
            }

            finish( url, nodes_to_add );
        } );

        req.open( "GET", url );
        req.send();
    }

    function finish ( url, nodes_to_add ) {
        node_blocks[url] = nodes_to_add;

        if ( Object.keys(node_blocks).length == link_elements.length ) {
            for ( var i = 0; i < link_elements.length; i++ ) {
                for ( var j = 0; j < node_blocks[ link_elements[i].href ].length; j++ ) {
                    document.body.appendChild( node_blocks[ link_elements[i].href ][j] );
                }
            }
        }
    }
} )();
