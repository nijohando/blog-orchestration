'use strict';

exports.handler = (event, context, callback) => {
    const response = {
        status: '401',
    };
    callback(null, response);
};
