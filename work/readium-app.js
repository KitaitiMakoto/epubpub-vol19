var $elementToBindTo = $("#reader");
var viewerPreferences = {
    fontSize: 12,
    syntheticLayout: false,
    currentMargin: 3,
    tocVisible: false,
    currentTheme: "default"
};
var epubName = encodeURI(location.hash.slice(1));
var epubViewer;
$.ajax({
    url: "/" + epubName + "/META-INF/container.xml",
    method: "get",
    type: "text",
    success: function(data, status, xhr) {
        var $rootfile = $(data.getElementsByTagName("rootfile")[0]);
        var rootfileUri = "/" + epubName + "/" + $rootfile.attr("full-path");
        $.ajax({
            url: rootfileUri,
            method: "get",
            type: "text",
            success: function(data, status, xhr) {
                var rootfileUriParts = rootfileUri.split("/");
                rootfileUriParts.pop();
                var epubViewer = new SimpleReadiumJs(
                    $elementToBindTo[0], viewerPreferences, rootfileUriParts.join("/") + "/", xhr.responseText, "lazy"
                );
                epubViewer.render();
                epubViewer.showSpineItem(0, function() {});

                $elementToBindTo
                    .find("iframe:first")
                    .attr("scrolling", "yes")
                    .on("load", function(event) {
                        $(event.target).contents()
                            .find("html:first")
                            .css("height", "")
                            .css("width", "100%");
                    });
            }
        });
    }
});
