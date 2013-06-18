document.onreadystatechange = function () {
    if (document.readState == "complete") {
        var filename = location.hash.slice(1);
        EPUBJS.filePath = ".";
        EPUBJSR.app.init("/" + encodeURI(filename));
    }
};
