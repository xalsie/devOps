import svelte from 'rollup-plugin-svelte';
import commonjs from '@rollup/plugin-commonjs';
import resolve from '@rollup/plugin-node-resolve';
import livereload from 'rollup-plugin-livereload';
import terser from '@rollup/plugin-terser';
import css from 'rollup-plugin-css-only';
import replace from '@rollup/plugin-replace';
import { spawn } from 'child_process';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.production' });

const production = !process.env.ROLLUP_WATCH;

// Debug: Afficher la valeur de VITE_BACKEND_URL
console.log('🔧 VITE_BACKEND_URL:', process.env.VITE_BACKEND_URL);
console.log('🔧 Production mode:', production);

function serve() {
	let server;

	function toExit() {
		if (server) server.kill(0);
	}

	return {
		writeBundle() {
			if (server) return;
			server = spawn('npm', ['run', 'start'], {
				stdio: ['ignore', 'inherit', 'inherit'],
				env: { ...process.env, NODE_ENV: 'development' }
			});

			process.on('SIGTERM', toExit);
			process.on('exit', toExit);
		}
	};
}

export default {
	input: 'src/main.js',
	output: {
		sourcemap: true,
		format: 'iife',
		name: 'app',
		file: 'public/build/bundle.js'
	},
	plugins: [
		replace({
			'process.env.NODE_ENV': JSON.stringify(production ? 'production' : 'development'),
			'__BACKEND_URL__': JSON.stringify(process.env.VITE_BACKEND_URL || 'http://localhost:3000'),
			preventAssignment: true
		}),
		svelte({
			compilerOptions: {
				dev: !production
			}
		}),
		css({ output: 'bundle.css' }),
		resolve({
			browser: true,
			dedupe: ['svelte']
		}),
		commonjs(),
		!production && serve(),
		!production && livereload('public'),
		production && terser()
	],
	watch: {
		clearScreen: false
	}
};
