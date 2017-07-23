// BASE SETUP
// =============================================================================

// call the packages we need
var express = require('express');
var bodyParser = require('body-parser');
var app = express();
var morgan = require('morgan');

// configure app
app.use(morgan('dev')); // log requests to the console

// configure body parser
app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

var allowCrossDomain = function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With');

    // intercept OPTIONS method
    if ('OPTIONS' == req.method) {
        res.send(200);
    } else {
        next();
    }
};

app.use(allowCrossDomain)

var port = process.env.PORT || 8080; // set our port

/*var mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/myDatabase'); // connect to our database
var User = require('./app/model/user');*/

// ROUTES FOR OUR API
// =============================================================================

// create our router
var router = express.Router();

// middleware to use for all requests
router.use(function(req, res, next) {
    // do logging
    console.log('Something is happening.');
    next();
});

// test route to make sure everything is working (accessed at GET http://localhost:8080/api)
router.get('/', function(req, res) {
    res.json({
        message: 'hooray! welcome to our api!'
    });
});

router.route('/login')

.post(function(req, res) {
    var response = {};

    if (req.body.username === 'admin' && req.body.password === 'admin') {
        var session = {
            authenticated: true,
            userId: 1,
            userName: req.body.username
        };
        response = {
            success: true,
            message: '',
            session: session
        }
    } else {
        response = {
            success: false,
            message: 'Usuário e/ou senha incorreto(s)'
        }
    }

    res.json(response);
})

router.route('/example')

.get(function(req, res) {
    var query = [];
    var count = 0;
    if (req.query.limit) {
        count = req.query.limit * 2;
    }

    for (var i = 1; i <= count; i++) {
        var user = {};
        user._ID = req.query.page + i;
        user.NOME = 'Nome ' + req.query.page + i;
        user.CPF = '39145592845';
        user.DATA = new Date();

        query.push(user);
    };

    var response = {
        recordCount: count,
        query: query
    }

    res.json(response);
})

.post(function(req, res) {
    var response = {
        success: true,
        message: 'Ação realizada com sucesso!'
    };

    res.json(response);
})

.delete(function(req, res) {
    var response = {
        success: true,
        message: ''
    };

    res.json(response);
});

router.route('/example/:id')

.get(function(req, res) {
    var query = [];

    var user = {};
    user.NOME = 'Nome ' + req.params.id;
    user.CPF = '39145592845';
    user.DATA = new Date();

    query.push(user);

    var response = {
        success: true,
        query: query
    }

    res.json(response);
})

.put(function(req, res) {
    var response = {
        success: true,
        message: 'Ação realizada com sucesso!'
    }

    res.json(response);
})

.delete(function(req, res) {
    var response = {
        success: true,
        message: 'Ação realizada com sucesso!'
    }

    res.json(response);
})

// REGISTER OUR ROUTES -------------------------------
app.use('/px-project-a1', router);

// START THE SERVER
// =============================================================================
app.listen(port);
console.log('Magic happens on port ' + port);