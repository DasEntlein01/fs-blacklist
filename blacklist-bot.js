const { Client, GatewayIntentBits } = require('discord.js');
const { REST } = require('@discordjs/rest');
const { Routes } = require('discord-api-types/v9');
const fs = require('fs');
const path = require('path');

const TOKEN = 'YOUR_TOKEN';
const CLIENT_ID = 'YOUR_CLIENTID';
const GUILD_ID = 'YOUR_GUILDID';

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

const blacklistFilePath = path.join('C:/xampp/htdocs/blacklist/blacklist.json'); // IMPORTENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! - path to webserver blacklist.json (cant be link!)

const loadBlacklist = () => {
    if (fs.existsSync(blacklistFilePath)) {
        return JSON.parse(fs.readFileSync(blacklistFilePath));
    }
    return [];
};

const saveBlacklist = (data) => {
    fs.writeFileSync(blacklistFilePath, JSON.stringify(data, null, 4));
};

const commands = [
    {
        name: 'blacklist',
        description: 'Füge eine IP zur Blacklist hinzu.',
        options: [
            {
                type: 3,
                name: 'ip',
                description: 'Die IP-Adresse, die hinzugefügt werden soll.',
                required: true,
            },
            {
                type: 3,
                name: 'reason',
                description: 'Der Grund für die Blacklist.',
                required: true,
            },
        ],
    },
    {
        name: 'unblacklist',
        description: 'Entferne eine IP von der Blacklist.',
        options: [
            {
                type: 3,
                name: 'ip',
                description: 'Die IP-Adresse, die entfernt werden soll.',
                required: true,
            },
        ],
    },
];

const rest = new REST({ version: '9' }).setToken(TOKEN);

(async () => {
    try {
        console.log('Starte das Registrieren der Slash-Befehle...');
        await rest.put(Routes.applicationGuildCommands(CLIENT_ID, GUILD_ID), { body: commands });
        console.log('Slash-Befehle registriert.');
    } catch (error) {
        console.error(error);
    }
})();

client.once('ready', () => {
    console.log(`Bot ist eingeloggt als ${client.user.tag}`);
});

const isAdmin = (member) => {
    return member.permissions.has('ADMINISTRATOR');
};

client.on('interactionCreate', async (interaction) => {
    if (!interaction.isCommand()) return;

    const { commandName, options, member } = interaction;

    if (!isAdmin(member)) {
        return await interaction.reply({ content: 'Du hast keine Berechtigung, diesen Befehl auszuführen.', ephemeral: true });
    }

    if (commandName === 'blacklist') {
        const ip = options.getString('ip');
        const reason = options.getString('reason');

        const blacklist = loadBlacklist();
        blacklist.push({ ip, reason });
        saveBlacklist(blacklist);

        await interaction.reply(`Die IP ${ip} wurde zur Blacklist hinzugefügt mit dem Grund: ${reason}`);
    } else if (commandName === 'unblacklist') {
        const ip = options.getString('ip');

        let blacklist = loadBlacklist();
        blacklist = blacklist.filter(entry => entry.ip !== ip);
        saveBlacklist(blacklist);

        await interaction.reply(`Die IP ${ip} wurde von der Blacklist entfernt.`);
    }
});

client.login(TOKEN);
