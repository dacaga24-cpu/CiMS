const PeakModel = require('../models/peakModel');

function badRequest(message) {
    const error = new Error(message);
    error.statusCode = 400;
    return error;
}

function parsePositiveInteger(value) {
    if (value === undefined || value === null || value === '') {
        return undefined;
    }
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 0) {
        return null;
    }
    return parsed;
}

const PeakService = {

    async getAll({ regionId, minAltitude, maxAltitude, search } = {}) {
        const parsedRegionId = parsePositiveInteger(regionId);
        const parsedMinAltitude = parsePositiveInteger(minAltitude);
        const parsedMaxAltitude = parsePositiveInteger(maxAltitude);

        if (parsedRegionId === null) {
            throw badRequest('Invalid regionId: must be a positive integer');
        }
        if (parsedMinAltitude === null) {
            throw badRequest('Invalid minAltitude: must be a positive integer');
        }
        if (parsedMaxAltitude === null) {
            throw badRequest('Invalid maxAltitude: must be a positive integer');
        }

        if (
            parsedMinAltitude !== undefined &&
            parsedMaxAltitude !== undefined &&
            parsedMinAltitude > parsedMaxAltitude
        ) {
            throw badRequest('minAltitude cannot be greater than maxAltitude');
        }

        return PeakModel.findAll({
            regionId: parsedRegionId,
            minAltitude: parsedMinAltitude,
            maxAltitude: parsedMaxAltitude,
            search: search ? String(search).trim() : undefined,
        });
    },

    async getById(id) {
        const peak = await PeakModel.findById(id);

        if (!peak) {
        const error = new Error('Peak not found');
        error.statusCode = 404;
        throw error;
        }

        return peak;
    },
};

module.exports = PeakService;