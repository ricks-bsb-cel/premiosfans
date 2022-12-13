"use strict";

const Joi = require('joi').extend(require('@joi/date'));
const moment = require("moment-timezone");

const global = require('../global');

const joiCustomValidator = {

    cpf: (value, joiHelpers) => {
        value = value.onlyNumbers();
        if (!global.isCPFValido(value)) {
            return joiHelpers.error('any.invalid.cpf');
        } else {
            return value;
        }
    },

    cnpj: (value, joiHelpers) => {
        value = value.onlyNumbers();
        if (!global.isCNPJValido(value)) {
            return joiHelpers.error('any.invalid.cnpj');
        } else {
            return value;
        }
    },

    cpfCnpj: (value, joiHelpers) => {
        value = value.onlyNumbers();
        if (!global.isCNPJValido(value) && !global.isCPFValido(value)) {
            return joiHelpers.error('any.invalid.cpfCnpj');
        } else {
            return value;
        }
    },

    dtNascimento: (value, joiHelpers) => {
        const dtNascimento = moment(value).tz("America/Sao_Paulo").format('YYYY-MM-DD');
        if (!global.isValidDtNascimento(dtNascimento)) {
            return joiHelpers.error('any.invalid.dtNascimento');
        } else {
            return value;
        }
    },

    celular: (value, joiHelpers) => {
        value = value.onlyNumbers();
        const format = global.formatPhoneNumber(value);
        if (!value || value.length === 0 || !format.success) {
            return joiHelpers.error('any.invalid.celular');
        } else {
            return format.celular;
        }
    },

    capitalize: (value, joiHelpers) => {
        return global.capitalize(value);
    },

    cep: (value, joiHelpers) => {
        return global.formatCep(value);
    }

}

const joiHelper = {

    id: attrs => {

        attrs.required = typeof attrs.required === 'undefined' ? true : attrs.required;

        let result = Joi.string();

        if (attrs.required) {
            result = result.required();
        }

        result = result
            .min(8)
            .max(128)
            .messages({
                'string.base': 'O ID dever ser uma texto',
                'any.required': 'O ID é de preenchimento obrigatório',
                'string.required': 'O ID é de preenchimento obrigatório',
                'string.min': 'O ID deve ter no mínimo 8 caracteres',
                'string.max': 'O ID deve ter no máximo 64 caracteres',
                'string.alphanum': 'O ID deve conter apenas caracteres a-z, A-Z e 0-9 (sem espaços)'
            })
            .description(attrs.description);

        if (attrs.defaultParent) {
            result = result.default(parent => { return parent[attrs.defaultParent]; })
        }

        return result;
    },

    cpfCnpj: attrs => {
        return Joi.string()
            .required()
            .custom(joiCustomValidator.cpfCnpj, 'Validação do CPF ou CNPJ')
            .messages({
                'string.required': 'O CPF ou CNPJ do é de preenchimento obrigatório',
                'string.pattern.base': 'O CPF ou CNPJ deve ter 11 posições',
                'string.base': 'O CPF ou CNPJ deve ser um texto',
                'any.invalid.cpfCnpj': 'O CPF ou CNPJ informado é inválido'
            })
            .description(attrs.description)
    },

    cpf: attrs => {
        return Joi.string()
            .required()
            .pattern(new RegExp('^[0-9]{11}$'))
            .custom(joiCustomValidator.cpf, 'Validação do CPF')
            .messages({
                'string.required': 'O CPF do é de preenchimento obrigatório',
                'string.pattern.base': 'O CPF deve ter 11 posições',
                'string.base': 'O CPF deve ser um texto',
                'any.invalid.cpf': 'O CPF informado é inválido'
            })
            .description(attrs.description)
    },

    cpf_formatted: attrs => {
        return Joi.string()
            .forbidden()
            .default(parent => {
                return parent[attrs.defaultParent] ? global.formatCpf(parent[attrs.defaultParent]) : null;
            })
            .messages({
                'any.unknown': 'Campo definido pela API. Não informe.'
            })
            .description('CPF formatado. Definido pela API.')
    },

    dtNascimento: attrs => {
        attrs.required = typeof attrs.required === 'undefined' ? false : attrs.required;

        let result = Joi
            .date()
            .format("YYYY-MM-DD")
            .raw();

        if (attrs.required) {
            result = result
                .required()
                .messages({
                    'any.required': 'A Data de Nascimento é de preenchimento obrigatório'
                });
        }

        result = result
            .custom(joiCustomValidator.dtNascimento, 'Validação da Data de Nascimento.')
            .messages({
                'any.required': 'A data de nascimento é obrigatória',
                'date.less': 'A data de nascimento deve ser inferior ao dia de hoje',
                'date.format': 'A data deve estar no formato ISO 8601 (YYYY-MM-DD)',
                'any.invalid.dtNascimento': 'A idade mínima é de 16 anos'
            })
            .description('Data de nascimento do cliente, no formato ISO 8601 (YYYY-MM-DD). A idade mínima é 16 de anos.');

        return result;
    },

    date_ddmmyyyy: attrs => {
        return Joi.string()
            .forbidden()
            .default(parent => {
                if (parent[attrs.parent]) {
                    return moment(parent[attrs.parent], 'YYYY-MM-DD').format('DD/MM/YYYY');
                } else {
                    return null;
                }
            })
            .messages({
                'any.unknown': 'Campo definido pela API. Não informe.'
            })
            .description('Data de nascimento no formato DD/MM/YYYY')
    },

    date_timestamp: attrs => {
        return Joi.string()
            .forbidden()
            .default(parent => {
                if (parent[attrs.parent]) {
                    return global.asTimestampData(parent[attrs.parent], true);
                } else {
                    return null;
                }
            })
            .messages({
                'any.unknown': 'Campo definido pela API. Não informe.'
            })
            .description('Data de nascimento em Firebase TimeStamp.')
    },

    cpfCnpj_formatted: attrs => {
        return Joi.string()
            .forbidden()
            .default(parent => {
                if (parent[attrs.defaultParent].onlyNumbers().length === 11) {
                    return parent[attrs.defaultParent] ? global.formatCpf(parent[attrs.defaultParent]) : null;
                } else if (parent[attrs.defaultParent].onlyNumbers().length === 14) {
                    return parent[attrs.defaultParent] ? global.formatCnpj(parent[attrs.defaultParent]) : null;
                } else {
                    return null;
                }
            })
            .messages({
                'any.unknown': 'Campo definido pela API. Não informe.'
            })
            .description('CPF ou CNPJ formatado. Definido pela API.')
    },

    celular: attrs => {
        attrs.required = typeof attrs.required === 'undefined' ? true : attrs.required;

        let result = Joi.string();

        if (attrs.required) {
            result = result
                .required()
                .messages({
                    'any.required': 'O celular é de preenchimento obrigatório'
                });
        }

        result = result
            .custom(joiCustomValidator.celular, 'Validação do Celular')
            .description(attrs.description);

        if (attrs.defaultParent) {
            result = result
                .default(parent => { return parent[attrs.defaultParent]; })
                .messages({
                    'any.invalid.celular': 'Número do celular inválido'
                });
        }

        return result;
    },

    celular_formatted: attrs => {
        return Joi.string()
            .forbidden()
            .default(parent => { return global.getFormatPhoneNumber(parent[attrs.defaultParent]); })
            .messages({
                'any.unknown': 'Campo definido pela API. Não informe.'
            })
            .description('Celular formatado. Definido pela API.')
    },

    email: attrs => {

        attrs.required = typeof attrs.required === 'undefined' ? true : attrs.required;

        let result = Joi.string()
            .email()
            .message('O email é inválido');

        if (attrs.required) {
            result = result.required().messages({
                'string.required': 'O email é de preenchimento obrigatório.'
            });
        }

        result = result
            .case('lower')
            .description(attrs.description);

        if (attrs.defaultParent) {
            result = result.default(parent => { return parent[attrs.defaultParent]; });
        }

        return result;
    },

    objEndereco: attrs => {

        const base = {
            cep: Joi.string()
                .pattern(new RegExp('^[0-9]{8}$'))
                .required()
                .messages({
                    'string.pattern.base': 'O cep deve conter 8 dígitos'
                })
                .description('CEP'),

            cep_formatted: Joi.string()
                .forbidden()
                .default(parent => { return global.formatCep(parent.cep); })
                .messages({
                    'any.unknown': 'Campo definido pela API. Não informe.'
                })
                .description('CEP formatado. Definido pela API.'),

            rua: Joi.string()
                .max(64)
                .required()
                .messages({
                    'string.max': 'A rua ou quadra deve conter no máximo 64 posições'
                })
                .description('Quadra ou Rua.'),

            bairro: Joi.string()
                .max(64)
                .required()
                .messages({
                    'string.max': 'O bairro deve conter no máximo 64 posições'
                })
                .description('Bairro do endereço.'),

            numero: Joi.string()
                .required()
                .max(16)
                .messages({
                    'string.max': 'O bairro deve conter no máximo 16 posições'
                })
                .description('Número da casa, rua, apartamento, etc. Caso não exista informe "sem número".'),

            cidade: Joi.string()
                .max(64)
                .required()
                .custom(joiCustomValidator.capitalize, 'Capitalized')
                .messages({
                    'string.max': 'A cidade deve conter no máximo 64 posições'
                })
                .description('Cidade'),

            estado: Joi.any()
                .valid('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')
                .required()
                .messages({
                    'any.only': 'O estado deve conter a sigla em maiúsculas de um dos estados brasileiros'
                })
                .description('Sigla do estado'),

            complemento: Joi.string()
                .max(64)
                .messages({
                    'string.max': 'O complemento deve conter no máximo 64 posições'
                })
                .description('Complemento do endereço')
        };

        let fields = {};

        Object.keys(base).forEach(k => {
            fields[(attrs.prefix || '') + k] = base[k];
        })

        let result = Joi
            .object(fields)
            .messages({
                'any.required': 'O endereço, se informado, deve conter CEP, rua, bairro, número, cdade e estado. Opcionalmente pode-se informar o complemento.'
            })
            .description(attrs.description);

        return result;
    }
}

exports.joiCustomValidator = joiCustomValidator;
exports.joiHelper = joiHelper;