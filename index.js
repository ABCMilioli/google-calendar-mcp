import { google } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';
import dotenv from 'dotenv';
import { z } from "zod";

dotenv.config();

// Initialize Google Calendar client
console.error(`Iniciando Oauth2Cliente...`);
console.error('São essas as variaveis definidas...');
console.error('GOOGLE_CLIENT_ID:', process.env.GOOGLE_CLIENT_ID || '[NÃO DEFINIDA]');
console.error('GOOGLE_CLIENT_SECRET:', process.env.GOOGLE_CLIENT_SECRET || '[NÃO DEFINIDA]');
console.error('GOOGLE_REDIRECT_URI:', process.env.GOOGLE_REDIRECT_URI || '[NÃO DEFINIDA]');
console.error('GOOGLE_REFRESH_TOKEN:', process.env.GOOGLE_REFRESH_TOKEN || '[NÃO DEFINIDA]');

const oauth2Client = new OAuth2Client({
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    redirectUri: process.env.GOOGLE_REDIRECT_URI,
});

// Set credentials from environment variables
oauth2Client.setCredentials({
    refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
});

const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

// Validation schemas
const schemas = {
    toolInputs: {
        listEvents: z.object({
            timeMin: z.string().optional(),
            timeMax: z.string().optional(),
            maxResults: z.number().optional(),
        }),
        createEvent: z.object({
            summary: z.string(),
            description: z.string().optional(),
            startTime: z.string(),
            endTime: z.string(),
            attendees: z.array(z.string()).optional(),
        }),
        updateEvent: z.object({
            eventId: z.string(),
            summary: z.string().optional(),
            description: z.string().optional(),
            startTime: z.string().optional(),
            endTime: z.string().optional(),
        }),
        deleteEvent: z.object({
            eventId: z.string(),
        }),
        findFreeTime: z.object({
            timeMin: z.string(),
            timeMax: z.string(),
            duration: z.number(), // duration in minutes
        })
    }
};

// Tool implementation handlers
const toolHandlers = {
    async list_events(args) {
        const { timeMin, timeMax, maxResults = 10 } = schemas.toolInputs.listEvents.parse(args);
        const response = await calendar.events.list({
            calendarId: 'primary',
            timeMin: timeMin || new Date().toISOString(),
            timeMax,
            maxResults,
            singleEvents: true,
            orderBy: 'startTime',
        });
        const events = response.data.items || [];
        const formattedEvents = events.map(event => {
            return `• ${event.summary}\n  Start: ${event.start?.dateTime || event.start?.date}\n  End: ${event.end?.dateTime || event.end?.date}\n  ID: ${event.id}`;
        }).join('\n\n');
        return {
            content: [{
                    type: "text",
                    text: events.length ?
                        `Found ${events.length} events:\n\n${formattedEvents}` :
                        "No events found in the specified time range."
                }]
        };
    },
    async create_event(args) {
        const { summary, description, startTime, endTime, attendees } = schemas.toolInputs.createEvent.parse(args);
        const event = await calendar.events.insert({
            calendarId: 'primary',
            requestBody: {
                summary,
                description,
                start: {
                    dateTime: startTime,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                end: {
                    dateTime: endTime,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                attendees: attendees?.map(email => ({ email })),
            },
        });
        return {
            content: [{
                    type: "text",
                    text: `Event created successfully!\nID: ${event.data.id}\nLink: ${event.data.htmlLink}`
                }]
        };
    },
    async update_event(args) {
        const { eventId, summary, description, startTime, endTime } = schemas.toolInputs.updateEvent.parse(args);
        // Get existing event
        const existingEvent = await calendar.events.get({
            calendarId: 'primary',
            eventId,
        });
        // Prepare update payload
        const updatePayload = {
            summary: summary || existingEvent.data.summary,
            description: description || existingEvent.data.description,
        };
        if (startTime) {
            updatePayload.start = {
                dateTime: startTime,
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            };
        }
        if (endTime) {
            updatePayload.end = {
                dateTime: endTime,
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            };
        }
        await calendar.events.update({
            calendarId: 'primary',
            eventId,
            requestBody: updatePayload,
        });
        return {
            content: [{
                    type: "text",
                    text: `Event ${eventId} updated successfully!`
                }]
        };
    },
    async delete_event(args) {
        const { eventId } = schemas.toolInputs.deleteEvent.parse(args);
        await calendar.events.delete({
            calendarId: 'primary',
            eventId,
        });
        return {
            content: [{
                    type: "text",
                    text: `Event ${eventId} deleted successfully!`
                }]
        };
    },
    async find_free_time(args) {
        const { timeMin, timeMax, duration } = schemas.toolInputs.findFreeTime.parse(args);
        // Get existing events in the time range
        const response = await calendar.events.list({
            calendarId: 'primary',
            timeMin,
            timeMax,
            singleEvents: true,
            orderBy: 'startTime',
        });
        const events = response.data.items || [];
        const freeTimes = [];
        let currentTime = new Date(timeMin);
        const endTime = new Date(timeMax);
        const durationMs = duration * 60000; // Convert minutes to milliseconds
        // Find free time slots
        for (const event of events) {
            const eventStart = new Date(event.start?.dateTime || event.start?.date || '');
            // Check if there's enough time before the event
            if (eventStart.getTime() - currentTime.getTime() >= durationMs) {
                freeTimes.push({
                    start: currentTime.toISOString(),
                    end: new Date(eventStart.getTime() - 1).toISOString(),
                });
            }
            currentTime = new Date(event.end?.dateTime || event.end?.date || '');
        }
        // Check for free time after the last event
        if (endTime.getTime() - currentTime.getTime() >= durationMs) {
            freeTimes.push({
                start: currentTime.toISOString(),
                end: endTime.toISOString(),
            });
        }
        const formattedTimes = freeTimes.map(slot => `• ${new Date(slot.start).toLocaleString()} - ${new Date(slot.end).toLocaleString()}`).join('\n');
        return {
            content: [{
                    type: "text",
                    text: freeTimes.length ?
                        `Encontrado ${freeTimes.length} nesse periodo:\n\n${formattedTimes}` :
                        `Nao encontrou tempo disponivel ${duration}.`
                }]
        };
    },
};

// CLI interface
const args = process.argv.slice(2);

if (args.length > 0) {
  // Execução direta via CLI com função e argumentos
  const funcao = args[0];
  const input = args[1] ? JSON.parse(args[1]) : {};

  if (toolHandlers[funcao]) {
    toolHandlers[funcao](input)
      .then((res) => {
        console.log(JSON.stringify(res, null, 2));
        process.exit(0);
      })
      .catch((err) => {
        console.error(`Erro ao executar ${funcao}:`, err);
        process.exit(1);
      });
  } else {
    console.error(`❌ Função desconhecida: ${funcao}`);
    process.exit(1);
  }
} else {
  // Modo interativo
  console.log("Google Calendar CLI");
  console.log("Comandos disponíveis:");
  console.log("  list_events [timeMin] [timeMax] [maxResults]");
  console.log("  create_event [summary] [description] [startTime] [endTime] [attendees]");
  console.log("  update_event [eventId] [summary] [description] [startTime] [endTime]");
  console.log("  delete_event [eventId]");
  console.log("  find_free_time [timeMin] [timeMax] [duration]");
  process.exit(0);
} 
