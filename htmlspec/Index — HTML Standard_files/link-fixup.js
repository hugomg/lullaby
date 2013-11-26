function fixBrokenLink(is404) {
    if (window.location.hash.length < 1 && !is404)
        return;

    var fragid = window.location.hash.substr(1);
    if (fragid && document.getElementById(fragid))
        return;

    var script = document.createElement('script');
    script.src = 'fragment-links.js';
    document.body.appendChild(script);
}