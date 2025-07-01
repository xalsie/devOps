<script>
	import { onMount } from 'svelte';
	
	export let name;
	
	let users = [];
	let loading = false;
	let error = null;
	let newUser = { name: '', email: '' };
	
	const API_URL = process.env.NODE_ENV === 'production' 
		? 'http://YOUR_BACKEND_IP:3000/api' 
		: 'http://localhost:3000/api';
	
	onMount(() => {
		fetchUsers();
	});
	
	async function fetchUsers() {
		loading = true;
		error = null;
		try {
			const response = await fetch(`${API_URL}/users`);
			if (!response.ok) throw new Error('Erreur lors de la récupération des utilisateurs');
			users = await response.json();
		} catch (e) {
			error = e.message;
			console.error('Erreur:', e);
		} finally {
			loading = false;
		}
	}
	
	async function addUser() {
		if (!newUser.name || !newUser.email) return;
		
		try {
			const response = await fetch(`${API_URL}/users`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify(newUser)
			});
			
			if (!response.ok) throw new Error('Erreur lors de l\'ajout de l\'utilisateur');
			
			newUser = { name: '', email: '' };
			await fetchUsers();
		} catch (e) {
			error = e.message;
			console.error('Erreur:', e);
		}
	}
	
	async function deleteUser(id) {
		try {
			const response = await fetch(`${API_URL}/users/${id}`, {
				method: 'DELETE'
			});
			
			if (!response.ok) throw new Error('Erreur lors de la suppression');
			
			await fetchUsers();
		} catch (e) {
			error = e.message;
			console.error('Erreur:', e);
		}
	}
</script>

<main>
	<div class="container">
		<header>
			<h1>🚀 {name}</h1>
			<p>Application frontend Svelte avec backend Node.js</p>
		</header>
		
		<section class="add-user">
			<h2>Ajouter un utilisateur</h2>
			<div class="form-group">
				<input
					bind:value={newUser.name}
					placeholder="Nom"
					type="text"
				/>
				<input
					bind:value={newUser.email}
					placeholder="Email"
					type="email"
				/>
				<button on:click={addUser} disabled={!newUser.name || !newUser.email}>
					Ajouter
				</button>
			</div>
		</section>
		
		<section class="users-list">
			<h2>Liste des utilisateurs</h2>
			
			{#if loading}
				<div class="loading">Chargement...</div>
			{:else if error}
				<div class="error">
					<p>❌ Erreur: {error}</p>
					<button on:click={fetchUsers}>Réessayer</button>
				</div>
			{:else if users.length === 0}
				<div class="empty">
					<p>Aucun utilisateur trouvé</p>
					<p>L'API backend est-elle accessible ?</p>
				</div>
			{:else}
				<div class="users-grid">
					{#each users as user (user._id)}
						<div class="user-card">
							<h3>{user.name}</h3>
							<p>{user.email}</p>
							<p class="date">Créé le: {new Date(user.createdAt).toLocaleDateString()}</p>
							<button 
								class="delete-btn" 
								on:click={() => deleteUser(user._id)}
							>
								Supprimer
							</button>
						</div>
					{/each}
				</div>
			{/if}
		</section>
		
		<footer>
			<p>Déployé avec Terraform sur AWS EC2 | Configuré avec Ansible</p>
		</footer>
	</div>
</main>

<style>
	main {
		padding: 2rem;
		min-height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	
	.container {
		max-width: 1200px;
		width: 100%;
		background: rgba(255, 255, 255, 0.95);
		border-radius: 20px;
		box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
		padding: 3rem;
		backdrop-filter: blur(10px);
	}
	
	header {
		text-align: center;
		margin-bottom: 3rem;
	}
	
	h1 {
		font-size: 3rem;
		margin: 0;
		background: linear-gradient(45deg, #667eea, #764ba2);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}
	
	header p {
		font-size: 1.2rem;
		color: #666;
		margin: 1rem 0;
	}
	
	section {
		margin-bottom: 3rem;
	}
	
	h2 {
		color: #333;
		border-bottom: 2px solid #667eea;
		padding-bottom: 0.5rem;
		margin-bottom: 1.5rem;
	}
	
	.form-group {
		display: grid;
		grid-template-columns: 1fr 1fr auto;
		gap: 1rem;
		align-items: center;
	}
	
	input {
		padding: 1rem;
		border: 2px solid #e0e0e0;
		border-radius: 10px;
		font-size: 1rem;
		transition: border-color 0.3s ease;
	}
	
	input:focus {
		outline: none;
		border-color: #667eea;
	}
	
	button {
		padding: 1rem 2rem;
		background: linear-gradient(45deg, #667eea, #764ba2);
		color: white;
		border: none;
		border-radius: 10px;
		font-size: 1rem;
		font-weight: bold;
		cursor: pointer;
		transition: transform 0.3s ease, box-shadow 0.3s ease;
	}
	
	button:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
	}
	
	button:disabled {
		opacity: 0.5;
		cursor: not-allowed;
		transform: none;
		box-shadow: none;
	}
	
	.users-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 1.5rem;
	}
	
	.user-card {
		background: white;
		border-radius: 15px;
		padding: 1.5rem;
		box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
		transition: transform 0.3s ease, box-shadow 0.3s ease;
	}
	
	.user-card:hover {
		transform: translateY(-5px);
		box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
	}
	
	.user-card h3 {
		margin: 0 0 0.5rem 0;
		color: #333;
	}
	
	.user-card p {
		margin: 0.5rem 0;
		color: #666;
	}
	
	.date {
		font-size: 0.9rem;
		color: #999;
	}
	
	.delete-btn {
		background: linear-gradient(45deg, #ff6b6b, #ee5a52);
		padding: 0.5rem 1rem;
		font-size: 0.9rem;
		margin-top: 1rem;
	}
	
	.loading, .error, .empty {
		text-align: center;
		padding: 2rem;
		background: rgba(255, 255, 255, 0.5);
		border-radius: 15px;
		margin: 1rem 0;
	}
	
	.error {
		background: rgba(255, 107, 107, 0.1);
		border: 2px solid rgba(255, 107, 107, 0.3);
	}
	
	.empty {
		background: rgba(255, 193, 7, 0.1);
		border: 2px solid rgba(255, 193, 7, 0.3);
	}
	
	footer {
		text-align: center;
		margin-top: 3rem;
		padding-top: 2rem;
		border-top: 1px solid #e0e0e0;
		color: #666;
	}
	
	@media (max-width: 768px) {
		.form-group {
			grid-template-columns: 1fr;
		}
		
		.users-grid {
			grid-template-columns: 1fr;
		}
		
		h1 {
			font-size: 2rem;
		}
		
		.container {
			padding: 1.5rem;
		}
	}
</style>
