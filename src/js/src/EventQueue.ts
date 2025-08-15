
export interface IEvent {
    type: string;
    value: any;
}

export type IEventQueue = {
    events: IEvent[];
};

export const eventQueue =
    {
        events: [] as IEvent[],
    };

export function popEvents(): IEvent[] {
    const events = eventQueue.events;
    eventQueue.events = [];
    return events;
}
